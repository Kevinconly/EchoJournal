import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:echo_journal/core/di/service_locator.dart';
import 'package:echo_journal/features/journal_entry/domain/entities/journal_entry.dart';
import 'package:echo_journal/features/journal_entry/domain/entities/mood.dart';
import 'package:echo_journal/features/journal_entry/domain/repositories/journal_repository.dart';
import 'package:echo_journal/features/journal_entry/domain/services/backup_service.dart';

class FakeJournalRepository implements JournalRepository {
  final List<JournalEntryEntity> _entries = [];
  int _idCounter = 1;

  @override
  Future<void> saveEntry(JournalEntryEntity entry) async {
    final toSave = entry.id == null
        ? entry.copyWith(id: _idCounter++)
        : entry;
    _entries.add(toSave);
  }

  @override
  Future<List<JournalEntryEntity>> getAllEntries() async {
    return List.from(_entries);
  }

  @override
  Future<JournalEntryEntity?> getEntryById(int id) async {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<JournalEntryEntity>> getEntriesByMood(Mood mood) async {
    return _entries.where((e) => e.mood == mood).toList();
  }

  @override
  Future<List<JournalEntryEntity>> getEntriesByDateRange(DateTime start, DateTime end) async {
    return _entries.where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end)).toList();
  }

  @override
  Future<void> updateEntry(JournalEntryEntity entry) async {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _entries[idx] = entry;
    }
  }

  @override
  Future<void> deleteEntry(int id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> deleteAllEntries() async {
    _entries.clear();
  }

  @override
  Future<int> getEntryCount() async => _entries.length;

  @override
  Future<List<JournalEntryEntity>> searchEntries(String query) async {
    final q = query.toLowerCase();
    return _entries.where((e) => e.text.toLowerCase().contains(q)).toList();
  }
}

void main() {
  group('BackupService Validation & Processing Tests', () {
    test('validateBackupData succeeds on valid version 1.0 schema', () {
      final validJson = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'totalEntries': 1,
        'entries': [
          {
            'content': 'Felt peaceful during evening walk',
            'mood': 'Calm',
            'createdAt': DateTime(2026, 11, 20, 18, 0).toIso8601String(),
            'tags': ['nature', 'evening'],
          }
        ]
      };

      final result = BackupService.validateBackupData(validJson);
      expect(result.isValid, isTrue);
      expect(result.validatedEntries.length, 1);
      expect(result.validatedEntries.first.text, 'Felt peaceful during evening walk');
      expect(result.validatedEntries.first.mood, Mood.calm);
      expect(result.validatedEntries.first.tags, ['nature', 'evening']);
    });

    test('validateBackupData succeeds on valid version 1.1 schema', () {
      final validJson = {
        'version': '1.1',
        'appName': 'EchoJournal',
        'exportDate': DateTime.now().toIso8601String(),
        'totalEntries': 1,
        'entries': [
          {
            'content': 'Deep work session completed',
            'mood': 'Excited',
            'createdAt': DateTime(2026, 11, 22, 10, 30).toIso8601String(),
            'tags': ['productivity'],
          }
        ]
      };

      final result = BackupService.validateBackupData(validJson);
      expect(result.isValid, isTrue);
      expect(result.validatedEntries.first.mood, Mood.excited);
    });

    test('validateBackupData rejects unsupported future versions', () {
      final invalidVersionJson = {
        'version': '9.9',
        'entries': []
      };

      final result = BackupService.validateBackupData(invalidVersionJson);
      expect(result.isValid, isFalse);
      expect(result.error, contains('Unsupported backup version'));
    });

    test('validateBackupData rejects non-map inputs', () {
      final result = BackupService.validateBackupData('not json');
      expect(result.isValid, isFalse);
      expect(result.error, contains('valid JSON object'));
    });

    test('validateBackupData rejects missing or empty content in entries', () {
      final invalidEntryJson = {
        'version': '1.1',
        'entries': [
          {
            'content': '   ',
            'mood': 'Calm',
            'createdAt': DateTime.now().toIso8601String(),
          }
        ]
      };

      final result = BackupService.validateBackupData(invalidEntryJson);
      expect(result.isValid, isFalse);
      expect(result.error, contains('missing content text'));
    });

    test('validateBackupData rejects malformed date strings', () {
      final invalidDateJson = {
        'version': '1.0',
        'entries': [
          {
            'content': 'Sample entry',
            'mood': 'Happy',
            'createdAt': 'not-a-valid-iso-date',
          }
        ]
      };

      final result = BackupService.validateBackupData(invalidDateJson);
      expect(result.isValid, isFalse);
      expect(result.error, contains('invalid date format'));
    });

    test('generateSignature creates identical signatures for matching content and timestamp', () {
      final timestamp = DateTime(2026, 5, 10, 14, 0);
      final sig1 = BackupService.generateSignature(timestamp, '   Today was productive! ');
      final sig2 = BackupService.generateSignature(timestamp, 'today was productive!');

      expect(sig1, equals(sig2));
    });

    test('getFileName handles both Windows backslashes and POSIX forward slashes', () {
      expect(BackupService.getFileName('C:\\Users\\User\\Documents\\backup.json'), 'backup.json');
      expect(BackupService.getFileName('/home/user/documents/backup.json'), 'backup.json');
    });

    test('exportEntriesToJson generates valid parseable JSON', () async {
      final fakeRepo = FakeJournalRepository();
      ServiceLocator.setJournalRepositoryForTesting(fakeRepo);

      await fakeRepo.saveEntry(JournalEntryEntity(
        text: 'Testing JSON export',
        mood: Mood.happy,
        timestamp: DateTime(2026, 11, 23, 12, 0),
        tags: const ['test'],
      ));

      final exported = await BackupService.exportEntriesToJson();
      final decoded = jsonDecode(exported) as Map<String, dynamic>;

      expect(decoded['version'], '1.1');
      expect(decoded['totalEntries'], 1);
      final entriesList = decoded['entries'] as List;
      expect(entriesList.first['content'], 'Testing JSON export');

      ServiceLocator.reset();
    });
  });
}
