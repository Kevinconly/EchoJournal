// Temporary fix: Use Hive instead of Isar to avoid namespace issues
// import 'package:isar/isar.dart';
import '../models/journal_entry_hive.dart';
import 'temp_database_service.dart' as temp_db;

class DatabaseService {
  // static late Isar _isar;
  static bool _initialized = false;

  // Initialize the database
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await temp_db.TempDatabaseService.init();
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  // Save a new journal entry
  static Future<void> saveEntry(JournalEntryHive entry) async {
    try {
      await temp_db.TempDatabaseService.saveEntry(entry);
    } catch (e) {
      throw Exception('Failed to save entry: $e');
    }
  }

  // Get all journal entries ordered by timestamp (newest first)
  static Future<List<JournalEntryHive>> getAllEntries() async {
    try {
      return await temp_db.TempDatabaseService.getAllEntries();
    } catch (e) {
      throw Exception('Failed to fetch entries: $e');
    }
  }

  // Get entries by mood
  static Future<List<JournalEntryHive>> getEntriesByMood(String mood) async {
    try {
      return await temp_db.TempDatabaseService.getEntriesByMood(mood);
    } catch (e) {
      throw Exception('Failed to fetch entries by mood: $e');
    }
  }

  // Get entries from a specific date range
  static Future<List<JournalEntryHive>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await temp_db.TempDatabaseService.getEntriesByDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to fetch entries by date range: $e');
    }
  }

  // Update an existing entry
  static Future<void> updateEntry(JournalEntryHive entry) async {
    try {
      await temp_db.TempDatabaseService.updateEntry(entry);
    } catch (e) {
      throw Exception('Failed to update entry: $e');
    }
  }

  // Delete an entry by id
  static Future<void> deleteEntry(int id) async {
    try {
      await temp_db.TempDatabaseService.deleteEntry(id);
    } catch (e) {
      throw Exception('Failed to delete entry: $e');
    }
  }

  // Delete all entries
  static Future<void> deleteAllEntries() async {
    try {
      await temp_db.TempDatabaseService.deleteAllEntries();
    } catch (e) {
      throw Exception('Failed to delete all entries: $e');
    }
  }

  // Get entry count
  static Future<int> getEntryCount() async {
    try {
      return await temp_db.TempDatabaseService.getEntryCount();
    } catch (e) {
      throw Exception('Failed to get entry count: $e');
    }
  }

  // Search entries by text content
  static Future<List<JournalEntryHive>> searchEntries(String query) async {
    try {
      return await temp_db.TempDatabaseService.searchEntries(query);
    } catch (e) {
      throw Exception('Failed to search entries: $e');
    }
  }

  // Close the database
  static Future<void> close() async {
    if (_initialized) {
      await temp_db.TempDatabaseService.close();
      _initialized = false;
    }
  }
}
