import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../entities/journal_entry.dart';
import '../entities/mood.dart';
import '../../data/repositories/journal_repository_impl.dart';

class BackupService {
  static JournalRepositoryImpl get _repository => 
      JournalRepositoryImpl();

  /// Export all journal entries to JSON
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
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'totalEntries': entries.length,
        'entries': exportData,
      };

      return const JsonEncoder.withIndent('  ').convert(jsonData);
    } catch (e) {
      throw Exception('Failed to export entries: $e');
    }
  }

  /// Save JSON data to local file
  static Future<String> saveBackupFile(String jsonData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toString().replaceAll(':', '-').replaceAll(' ', '_');
      final fileName = 'echojournal_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonData);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save backup file: $e');
    }
  }

  /// Export and save entries to user-selected location
  static Future<String?> exportBackup() async {
    try {
      // Generate JSON data
      final jsonData = await exportEntriesToJson();

      // Let user pick save location (desktop & supported mobile platforms).
      // On Android/iOS, file_picker requires passing bytes when saving.
      final fileName = 'echojournal_backup_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}.json';
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
        // Some platforms (e.g. web) may not support saveFile.
        pickerSupported = false;
      }

      // If the user explicitly canceled the file picker, return null to allow
      // callers to treat it as a no-op instead of an error.
      if (pickerSupported && selectedPath == null) {
        return null;
      }

      if (selectedPath != null) {
        // In some environments (e.g. Android SAF) the returned path may not be a
        // local file system path. Avoid attempting to write again in that case.
        if (_isLocalFilePath(selectedPath)) {
          final file = File(selectedPath);
          if (!await file.exists()) {
            await file.writeAsString(jsonData);
          }
        }
        return selectedPath;
      }

      // Fallback: save to app documents directory
      return await saveBackupFile(jsonData);
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  static bool _isLocalFilePath(String path) {
    // Covers UNIX-like and Windows file paths.
    return path.startsWith('/') || RegExp(r'^[a-zA-Z]:\\').hasMatch(path);
  }

  /// Import entries from JSON file
  static Future<ImportResult> importFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          success: false,
          error: 'File does not exist',
          importedCount: 0,
        );
      }

      final jsonData = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonData);

      // Validate file format
      if (!_isValidBackupFormat(data)) {
        return ImportResult(
          success: false,
          error: 'Invalid backup file format',
          importedCount: 0,
        );
      }

      final List<dynamic> entriesData = data['entries'];
      int importedCount = 0;
      final List<String> errors = [];

      for (final entryData in entriesData) {
        try {
          final entry = _parseEntryFromJson(entryData);
          await _repository.saveEntry(entry);
          importedCount++;
        } catch (e) {
          errors.add('Entry ${importedCount + 1}: $e');
        }
      }

      return ImportResult(
        success: true,
        importedCount: importedCount,
        errors: errors,
        totalEntries: entriesData.length,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Failed to import backup: $e',
        importedCount: 0,
      );
    }
  }

  /// Pick and import JSON backup file
  static Future<ImportResult> importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select EchoJournal Backup',
        type: FileType.custom,
        allowedExtensions: ['json'],
        lockParentWindow: true,
      );

      if (result != null && result.files.single.path != null) {
        return await importFromJson(result.files.single.path!);
      } else {
        return ImportResult(
          success: false,
          error: 'No file selected',
          importedCount: 0,
        );
      }
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Failed to pick file: $e',
        importedCount: 0,
      );
    }
  }

  static bool _isValidBackupFormat(Map<String, dynamic> data) {
    return data.containsKey('version') &&
           data.containsKey('exportDate') &&
           data.containsKey('totalEntries') &&
           data.containsKey('entries') &&
           data['entries'] is List;
  }

  static JournalEntryEntity _parseEntryFromJson(Map<String, dynamic> entryData) {
    final moodString = entryData['mood'] as String;
    final mood = Mood.values.firstWhere(
      (m) => m.label.toLowerCase() == moodString.toLowerCase(),
      orElse: () => Mood.calm,
    );

    return JournalEntryEntity(
      id: null,
      text: entryData['content'] as String,
      mood: mood,
      timestamp: DateTime.parse(entryData['createdAt'] as String),
      tags: (entryData['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ImportResult {
  final bool success;
  final String? error;
  final int importedCount;
  final int totalEntries;
  final List<String>? errors;

  ImportResult({
    required this.success,
    this.error,
    required this.importedCount,
    this.totalEntries = 0,
    this.errors,
  });

  bool get hasErrors => errors != null && errors!.isNotEmpty;
}
