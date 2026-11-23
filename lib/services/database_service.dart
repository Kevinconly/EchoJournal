import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/journal_entry_hive.dart';

/// Authoritative Hive database service for EchoJournal.
/// Manages box lifecycle, schema adapter registration, and persistence operations.
class DatabaseService {
  static const String boxName = 'journal_entries';
  static Box<JournalEntryHive>? _box;
  static bool _initialized = false;

  /// Check whether the database is initialized.
  static bool get isInitialized => _initialized && _box != null && _box!.isOpen;

  /// Initialize the database and register Hive adapters if not already done.
  static Future<void> init({String? customPath}) async {
    if (isInitialized) return;

    try {
      if (customPath != null) {
        Hive.init(customPath);
      } else {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        Hive.init(appDocumentDir.path);
      }

      final adapter = JournalEntryHiveAdapter();
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }

      _box = await Hive.openBox<JournalEntryHive>(boxName);
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  /// Get the active Box instance. Throws if not initialized.
  static Box<JournalEntryHive> get box {
    if (!isInitialized) {
      throw StateError('Database not initialized. Call DatabaseService.init() first.');
    }
    return _box!;
  }

  /// Save a new or existing journal entry.
  /// If entry.id <= 0, assigns auto-increment key from Hive and synchronizes entry.id.
  static Future<int> saveEntry(JournalEntryHive entry) async {
    try {
      final currentBox = box;
      if (entry.id <= 0) {
        final int key = await currentBox.add(entry);
        entry.id = key;
        await currentBox.put(key, entry);
        return key;
      } else {
        await currentBox.put(entry.id, entry);
        return entry.id;
      }
    } catch (e) {
      throw Exception('Failed to save entry: $e');
    }
  }

  /// Get all journal entries ordered by timestamp (newest first).
  static Future<List<JournalEntryHive>> getAllEntries() async {
    try {
      final currentBox = box;
      final entries = currentBox.toMap().entries.map((e) {
        final entry = e.value;
        if (e.key is int && entry.id != e.key) {
          entry.id = e.key as int;
        }
        return entry;
      }).toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      throw Exception('Failed to fetch entries: $e');
    }
  }

  /// Get an entry by its ID.
  static Future<JournalEntryHive?> getEntryById(int id) async {
    try {
      final currentBox = box;
      final entry = currentBox.get(id);
      if (entry != null && entry.id != id) {
        entry.id = id;
      }
      return entry;
    } catch (e) {
      throw Exception('Failed to fetch entry by ID: $e');
    }
  }

  /// Get entries filtered by mood label.
  static Future<List<JournalEntryHive>> getEntriesByMood(String mood) async {
    try {
      final currentBox = box;
      final entries = currentBox.toMap().entries
          .where((e) => e.value.mood.toLowerCase() == mood.toLowerCase())
          .map((e) {
            final entry = e.value;
            if (e.key is int && entry.id != e.key) {
              entry.id = e.key as int;
            }
            return entry;
          })
          .toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      throw Exception('Failed to fetch entries by mood: $e');
    }
  }

  /// Get entries from a specific date range.
  static Future<List<JournalEntryHive>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final currentBox = box;
      final entries = currentBox.toMap().entries
          .where((e) =>
              e.value.timestamp.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              e.value.timestamp.isBefore(endDate.add(const Duration(seconds: 1))))
          .map((e) {
            final entry = e.value;
            if (e.key is int && entry.id != e.key) {
              entry.id = e.key as int;
            }
            return entry;
          })
          .toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      throw Exception('Failed to fetch entries by date range: $e');
    }
  }

  /// Update an existing entry.
  static Future<void> updateEntry(JournalEntryHive entry) async {
    try {
      if (entry.id <= 0) {
        await saveEntry(entry);
        return;
      }
      await box.put(entry.id, entry);
    } catch (e) {
      throw Exception('Failed to update entry: $e');
    }
  }

  /// Delete an entry by ID.
  static Future<void> deleteEntry(int id) async {
    try {
      await box.delete(id);
    } catch (e) {
      throw Exception('Failed to delete entry: $e');
    }
  }

  /// Delete all entries from the box.
  static Future<void> deleteAllEntries() async {
    try {
      await box.clear();
    } catch (e) {
      throw Exception('Failed to delete all entries: $e');
    }
  }

  /// Get entry count.
  static Future<int> getEntryCount() async {
    try {
      return box.length;
    } catch (e) {
      throw Exception('Failed to get entry count: $e');
    }
  }

  /// Search entries by text content or tags.
  static Future<List<JournalEntryHive>> searchEntries(String query) async {
    try {
      final lower = query.toLowerCase();
      final currentBox = box;
      final entries = currentBox.toMap().entries
          .where((e) {
            final entry = e.value;
            final matchesText = entry.text.toLowerCase().contains(lower);
            final matchesMood = entry.mood.toLowerCase().contains(lower);
            final matchesTag = entry.tags.any((tag) => tag.toLowerCase().contains(lower));
            return matchesText || matchesMood || matchesTag;
          })
          .map((e) {
            final entry = e.value;
            if (e.key is int && entry.id != e.key) {
              entry.id = e.key as int;
            }
            return entry;
          })
          .toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      throw Exception('Failed to search entries: $e');
    }
  }

  /// Close the database and release box resources.
  static Future<void> close() async {
    if (_initialized) {
      await _box?.close();
      _box = null;
      await Hive.close();
      _initialized = false;
    }
  }
}
