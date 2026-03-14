import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/journal_entry_hive.dart';

class TempDatabaseService {
  static late Box<JournalEntryHive> _box;
  static bool _initialized = false;

  // Initialize the database
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
      
      // Register the adapter if not already registered
      if (!Hive.isAdapterRegistered(JournalEntryHiveAdapter().typeId)) {
        Hive.registerAdapter(JournalEntryHiveAdapter());
      }
      
      _box = await Hive.openBox<JournalEntryHive>('journal_entries');
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  // Get the box instance
  static Box<JournalEntryHive> get box {
    if (!_initialized) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _box;
  }

  // Save a new journal entry
  static Future<void> saveEntry(JournalEntryHive entry) async {
    try {
      if (entry.id <= 0) {
        // Let Hive assign an auto-increment key for new entries.
        final int key = await _box.add(entry);
        // Ensure the stored object has its id field updated.
        entry.id = key;
        await _box.put(key, entry);
      } else {
        await _box.put(entry.id, entry);
      }
    } catch (e) {
      throw Exception('Failed to save entry: $e');
    }
  }

  // Get all journal entries ordered by timestamp (newest first)
  static Future<List<JournalEntryHive>> getAllEntries() async {
    try {
      final entries = _box.toMap().entries.map((e) {
        final entry = e.value;
        entry.id = e.key;
        return entry;
      }).toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      throw Exception('Failed to fetch entries: $e');
    }
  }

  // Get entries by mood
  static Future<List<JournalEntryHive>> getEntriesByMood(String mood) async {
    try {
      final entries = _box.toMap().entries
          .where((e) => e.value.mood == mood)
          .map((e) {
            final entry = e.value;
            entry.id = e.key;
            return entry;
          })
          .toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
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
      final entries = _box.toMap().entries
          .where((e) =>
              e.value.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
              e.value.timestamp.isBefore(endDate.add(const Duration(days: 1))))
          .map((e) {
            final entry = e.value;
            entry.id = e.key;
            return entry;
          })
          .toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      throw Exception('Failed to fetch entries by date range: $e');
    }
  }

  // Update an existing entry
  static Future<void> updateEntry(JournalEntryHive entry) async {
    try {
      if (entry.id <= 0) {
        // If id isn't set, treat as a new entry.
        await saveEntry(entry);
        return;
      }
      await _box.put(entry.id, entry);
    } catch (e) {
      throw Exception('Failed to update entry: $e');
    }
  }

  // Delete an entry by id
  static Future<void> deleteEntry(int id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw Exception('Failed to delete entry: $e');
    }
  }

  // Delete all entries
  static Future<void> deleteAllEntries() async {
    try {
      await _box.clear();
    } catch (e) {
      throw Exception('Failed to delete all entries: $e');
    }
  }

  // Get entry count
  static Future<int> getEntryCount() async {
    try {
      return _box.length;
    } catch (e) {
      throw Exception('Failed to get entry count: $e');
    }
  }

  // Search entries by text content
  static Future<List<JournalEntryHive>> searchEntries(String query) async {
    try {
      final entries = _box.toMap().entries
          .where((e) => e.value.text.toLowerCase().contains(query.toLowerCase()))
          .map((e) {
            final entry = e.value;
            entry.id = e.key;
            return entry;
          })
          .toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      throw Exception('Failed to search entries: $e');
    }
  }

  // Close the database
  static Future<void> close() async {
    if (_initialized) {
      await _box.close();
      await Hive.close();
      _initialized = false;
    }
  }
}
