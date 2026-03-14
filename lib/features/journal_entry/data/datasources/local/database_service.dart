// Temporary fix: Comment out entire Isar-based database service
// This conflicts with our main database service that now uses Hive

/*
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/journal_entry_model.dart';

class DatabaseService {
  static late Isar _isar;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [JournalEntryModelSchema],
        directory: dir.path,
        name: 'echo_journal',
      );
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  static Isar get isar {
    if (!_initialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _isar;
  }

  static Future<void> saveEntry(JournalEntryModel entry) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journalEntryModels.put(entry);
      });
    } catch (e) {
      throw Exception('Failed to save entry: $e');
    }
  }

  static Future<List<JournalEntryModel>> getAllEntries() async {
    try {
      return await _isar.journalEntryModels
          .where()
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch entries: $e');
    }
  }

  static Future<List<JournalEntryModel>> getEntriesByMood(String mood) async {
    try {
      return await _isar.journalEntryModels
          .filter()
          .moodEqualTo(mood)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch entries by mood: $e');
    }
  }

  static Future<List<JournalEntryModel>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _isar.journalEntryModels
          .filter()
          .createdAtBetween(startDate, endDate)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch entries by date range: $e');
    }
  }

  static Future<void> updateEntry(JournalEntryModel entry) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journalEntryModels.put(entry);
      });
    } catch (e) {
      throw Exception('Failed to update entry: $e');
    }
  }

  static Future<void> deleteEntry(int id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journalEntryModels.delete(id);
      });
    } catch (e) {
      throw Exception('Failed to delete entry: $e');
    }
  }

  static Future<void> deleteAllEntries() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journalEntryModels.clear();
      });
    } catch (e) {
      throw Exception('Failed to delete all entries: $e');
    }
  }

  static Future<int> getEntryCount() async {
    try {
      return await _isar.journalEntryModels.count();
    } catch (e) {
      throw Exception('Failed to get entry count: $e');
    }
  }

  static Future<List<JournalEntryModel>> searchEntries(String query) async {
    try {
      return await _isar.journalEntryModels
          .filter()
          .contentContains(query, caseSensitive: false)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to search entries: $e');
    }
  }

  static Future<void> close() async {
    if (_initialized) {
      await _isar.close();
      _initialized = false;
    }
  }
}
*/
