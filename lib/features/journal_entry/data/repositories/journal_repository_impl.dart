import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/mood.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/local/database_service.dart';
import '../models/journal_entry_model.dart';

class JournalRepositoryImpl implements JournalRepository {
  JournalRepositoryImpl();

  @override
  Future<void> saveEntry(JournalEntryEntity entry) async {
    final model = JournalEntryModel.fromEntity(entry);
    await DatabaseService.saveEntry(model);
  }

  @override
  Future<List<JournalEntryEntity>> getAllEntries() async {
    final models = await DatabaseService.getAllEntries();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<JournalEntryEntity>> getEntriesByMood(Mood mood) async {
    final models = await DatabaseService.getEntriesByMood(mood.label);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<JournalEntryEntity>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final models = await DatabaseService.getEntriesByDateRange(startDate, endDate);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> updateEntry(JournalEntryEntity entry) async {
    final model = JournalEntryModel.fromEntity(entry);
    await DatabaseService.updateEntry(model);
  }

  @override
  Future<void> deleteEntry(int id) async {
    await DatabaseService.deleteEntry(id);
  }

  @override
  Future<void> deleteAllEntries() async {
    await DatabaseService.deleteAllEntries();
  }

  @override
  Future<int> getEntryCount() async {
    return await DatabaseService.getEntryCount();
  }

  @override
  Future<List<JournalEntryEntity>> searchEntries(String query) async {
    final models = await DatabaseService.searchEntries(query);
    return models.map((model) => model.toEntity()).toList();
  }
}
