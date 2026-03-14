import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class SaveJournalEntryUseCase {
  final JournalRepository _repository;

  SaveJournalEntryUseCase(this._repository);

  Future<void> call(JournalEntryEntity entry) async {
    await _repository.saveEntry(entry);
  }
}
