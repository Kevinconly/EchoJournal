import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/di/service_locator.dart';
import '../entities/journal_entry.dart';
import '../entities/mood.dart';
import '../repositories/journal_repository.dart';

enum ImportMode {
  merge,
  replace,
}

class ValidationResult {
  final bool isValid;
  final String? error;
  final List<JournalEntryEntity> validatedEntries;

  const ValidationResult({
    required this.isValid,
    this.error,
    this.validatedEntries = const [],
  });

  factory ValidationResult.success(List<JournalEntryEntity> entries) {
    return ValidationResult(isValid: true, validatedEntries: entries);
  }

  factory ValidationResult.failure(String error) {
    return ValidationResult(isValid: false, error: error);
  }
}

class ImportResult {
  final bool success;
  final bool isCancelled;
  final String? error;
  final int importedCount;
  final int skippedDuplicates;
  final int totalEntries;
  final List<String> errors;

  const ImportResult({
    required this.success,
    this.isCancelled = false,
    this.error,
    required this.importedCount,
    this.skippedDuplicates = 0,
    this.totalEntries = 0,
    this.errors = const [],
  });

  factory ImportResult.cancelled() {
    return const ImportResult(
      success: false,
      isCancelled: true,
      importedCount: 0,
    );
  }

  factory ImportResult.failure(String error) {
    return ImportResult(
      success: false,
      error: error,
      importedCount: 0,
    );
  }

  bool get hasErrors => errors.isNotEmpty;
}

class BackupService {
  static const String currentVersion = '1.1';
  static const Set<String> supportedVersions = {'1.0', '1.1'};

  static JournalRepository get _repository => ServiceLocator.journalRepository;

  /// Generate a deduplication signature from entry content and timestamp
  static String generateSignature(DateTime timestamp, String text) {
    return '${timestamp.millisecondsSinceEpoch}_${text.trim().toLowerCase()}';
  }

  /// Extracts the base file name from a path on either Windows or POSIX systems
  static String getFileName(String path) {
    final sanitized = path.replaceAll('\\', '/');
    return sanitized.split('/').last;
  }

  /// Export all journal entries to a formatted JSON string
  static Future<String> exportEntriesToJson() async {
    try {
      final entries = await _repository.getAllEntries();

      final exportData = entries.map((entry) => {
        'id': entry.id,
        'content': entry.text,
        'mood': entry.mood.label,
        'createdAt': entry.timestamp.toIso8601String(),
        'tags': entry.tags,
      }).toList();

      final jsonData = {
        'version': currentVersion,
        'appName': 'EchoJournal',
        'exportDate': DateTime.now().toIso8601String(),
        'totalEntries': entries.length,
        'entries': exportData,
      };

      return const JsonEncoder.withIndent('  ').convert(jsonData);
    } catch (e) {
      throw Exception('Failed to export entries: $e');
    }
  }

  /// Save JSON data to local app documents file as a fallback
  static Future<String> saveBackupFile(String jsonData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'echojournal_backup_$dateStr.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonData);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save backup file: $e');
    }
  }

  /// Export and save entries to a user-selected location
  static Future<String?> exportBackup() async {
    try {
      final jsonData = await exportEntriesToJson();
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final fileName = 'echojournal_backup_$dateStr.json';

      String? selectedPath;
      bool pickerSupported = true;

      try {
        selectedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save EchoJournal Backup',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          lockParentWindow: true,
          bytes: utf8.encode(jsonData),
        );
      } catch (_) {
        pickerSupported = false;
      }

      if (pickerSupported && selectedPath == null) {
        return null; // Explicit user cancellation
      }

      if (selectedPath != null) {
        if (_isLocalFilePath(selectedPath)) {
          final file = File(selectedPath);
          if (!await file.exists()) {
            await file.writeAsString(jsonData);
          }
        }
        return selectedPath;
      }

      return await saveBackupFile(jsonData);
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  static bool _isLocalFilePath(String path) {
    return path.startsWith('/') || RegExp(r'^[a-zA-Z]:\\').hasMatch(path);
  }

  /// Strictly validates backup data before touching the database
  static ValidationResult validateBackupData(dynamic decodedJson) {
    if (decodedJson is! Map<String, dynamic>) {
      return ValidationResult.failure('Backup file is not a valid JSON object.');
    }

    final version = decodedJson['version']?.toString();
    if (version == null || !supportedVersions.contains(version)) {
      return ValidationResult.failure(
        'Unsupported backup version: "${version ?? 'unknown'}". Supported versions: ${supportedVersions.join(', ')}.',
      );
    }

    final rawEntries = decodedJson['entries'];
    if (rawEntries is! List) {
      return ValidationResult.failure('Backup missing "entries" list.');
    }

    final parsedEntries = <JournalEntryEntity>[];
    for (int i = 0; i < rawEntries.length; i++) {
      final item = rawEntries[i];
      if (item is! Map) {
        return ValidationResult.failure('Entry at index $i is not a valid object.');
      }

      final content = item['content'] ?? item['text'];
      if (content == null || content is! String || content.trim().isEmpty) {
        return ValidationResult.failure('Entry at index $i is missing content text.');
      }

      final createdAtRaw = item['createdAt'] ?? item['timestamp'];
      if (createdAtRaw == null) {
        return ValidationResult.failure('Entry at index $i is missing creation date.');
      }

      DateTime timestamp;
      try {
        timestamp = DateTime.parse(createdAtRaw.toString());
      } catch (e) {
        return ValidationResult.failure('Entry at index $i has invalid date format: $createdAtRaw');
      }

      final moodStr = item['mood']?.toString() ?? 'Calm';
      final mood = Mood.fromString(moodStr);

      final tagsRaw = item['tags'];
      final List<String> tags = [];
      if (tagsRaw is List) {
        for (final tag in tagsRaw) {
          if (tag != null) tags.add(tag.toString().trim());
        }
      }

      parsedEntries.add(JournalEntryEntity(
        id: null, // Let database generate id or manage it safely
        text: content.trim(),
        mood: mood,
        timestamp: timestamp,
        tags: tags,
      ));
    }

    return ValidationResult.success(parsedEntries);
  }

  /// Import entries from a JSON file path with validation and de-duplication
  static Future<ImportResult> importFromJson(
    String filePath, {
    ImportMode mode = ImportMode.merge,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult.failure('File does not exist: ${getFileName(filePath)}');
      }

      final jsonContent = await file.readAsString();
      dynamic decoded;
      try {
        decoded = jsonDecode(jsonContent);
      } catch (e) {
        return ImportResult.failure('Invalid JSON syntax: $e');
      }

      final validation = validateBackupData(decoded);
      if (!validation.isValid) {
        return ImportResult.failure(validation.error ?? 'Validation failed.');
      }

      final entriesToImport = validation.validatedEntries;
      int importedCount = 0;
      int skippedDuplicates = 0;
      final errors = <String>[];

      if (mode == ImportMode.replace) {
        await _repository.deleteAllEntries();
        for (final entry in entriesToImport) {
          try {
            await _repository.saveEntry(entry);
            importedCount++;
          } catch (e) {
            errors.add('Failed to import entry: $e');
          }
        }
      } else {
        // Merge mode: deduplicate against existing database entries
        final existingEntries = await _repository.getAllEntries();
        final existingSignatures = existingEntries
            .map((e) => generateSignature(e.timestamp, e.text))
            .toSet();

        for (final entry in entriesToImport) {
          final sig = generateSignature(entry.timestamp, entry.text);
          if (existingSignatures.contains(sig)) {
            skippedDuplicates++;
            continue;
          }

          try {
            await _repository.saveEntry(entry);
            existingSignatures.add(sig);
            importedCount++;
          } catch (e) {
            errors.add('Failed to import entry: $e');
          }
        }
      }

      return ImportResult(
        success: true,
        importedCount: importedCount,
        skippedDuplicates: skippedDuplicates,
        totalEntries: entriesToImport.length,
        errors: errors,
      );
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }

  /// Pick and import a JSON backup file
  static Future<ImportResult> importBackup({
    ImportMode mode = ImportMode.merge,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select EchoJournal Backup',
        type: FileType.custom,
        allowedExtensions: ['json'],
        lockParentWindow: true,
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return ImportResult.cancelled();
      }

      return await importFromJson(result.files.single.path!, mode: mode);
    } catch (e) {
      return ImportResult.failure('Failed to pick file: $e');
    }
  }
}
