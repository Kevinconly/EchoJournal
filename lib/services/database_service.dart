import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/journal_entry.dart';

class DatabaseService {
  static late Isar _isar;
  static bool _initialized = false;

  // Initialize the database
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [JournalEntrySchema],
        directory: dir.path,
      );
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  // Get the Isar instance
  static Isar get isar {
    if (!_initialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _isar;
  }

  // Save a new journal entry
  static Future<void> saveEntry(JournalEntry entry) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journalEntrys.put(entry);
      });
    } catch (e) {
      throw Exception('Failed to save entry: $e');
    }
  }

  // Get all journal entries ordered by timestamp (newest first)
  static Future<List<JournalEntry>> getAllEntries() async {
    try {
      return await _isar.journalEntrys
          .where()
          .sortByTimestampDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch entries: $e');
    }
  }

  // Get entries by mood
  static Future<List<JournalEntry>> getEntriesByMood(String mood) async {
    try {
      return await _isar.journalEntrys
          .filter()
          .moodEqualTo(mood)
          .sortByTimestampDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch entries by mood: $e');
    }
  }

  // Get entries from a specific date range
  static Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _isar.journalEntrys
          .filter()
          .timestampBetween(startDate, endDate)
          .sortByTimestampDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch entries by date range: $e');
    }
  }

  // Update an existing entry
  static Future<void> updateEntry(JournalEntry entry) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journalEntrys.put(entry);
      });
    } catch (e) {
      throw Exception('Failed to update entry: $e');
    }
  }

  // Delete an entry by id
  static Future<void> deleteEntry(int id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journalEntrys.delete(id);
      });
    } catch (e) {
      throw Exception('Failed to delete entry: $e');
    }
  }

  // Delete all entries
  static Future<void> deleteAllEntries() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.journalEntrys.clear();
      });
    } catch (e) {
      throw Exception('Failed to delete all entries: $e');
    }
  }

  // Get entry count
  static Future<int> getEntryCount() async {
    try {
      return await _isar.journalEntrys.count();
    } catch (e) {
      throw Exception('Failed to get entry count: $e');
    }
  }

  // Search entries by text content
  static Future<List<JournalEntry>> searchEntries(String query) async {
    try {
      return await _isar.journalEntrys
          .filter()
          .textContains(query, caseSensitive: false)
          .sortByTimestampDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to search entries: $e');
    }
  }

  // Close the database
  static Future<void> close() async {
    if (_initialized) {
      await _isar.close();
      _initialized = false;
    }
  }
}
