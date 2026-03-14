import '../entities/journal_entry.dart';
import '../entities/mood.dart';

abstract class JournalRepository {
  Future<void> saveEntry(JournalEntryEntity entry);
  Future<List<JournalEntryEntity>> getAllEntries();
  Future<List<JournalEntryEntity>> getEntriesByMood(Mood mood);
  Future<List<JournalEntryEntity>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<void> updateEntry(JournalEntryEntity entry);
  Future<void> deleteEntry(int id);
  Future<void> deleteAllEntries();
  Future<int> getEntryCount();
  Future<List<JournalEntryEntity>> searchEntries(String query);
}
