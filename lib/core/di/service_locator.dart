import '../../features/journal_entry/data/repositories/journal_repository_impl.dart';
import '../../features/journal_entry/domain/repositories/journal_repository.dart';
import '../../features/journal_entry/domain/services/cached_repository.dart';

/// Central dependency locator for EchoJournal.
/// Provides a shared repository instance ensuring cache synchronization across all screens.
class ServiceLocator {
  static JournalRepository _journalRepository = CachedRepository(JournalRepositoryImpl());

  /// Shared journal repository instance.
  static JournalRepository get journalRepository => _journalRepository;

  /// Replace instance for unit/widget testing.
  static void setJournalRepositoryForTesting(JournalRepository repository) {
    _journalRepository = repository;
  }

  /// Reset to default cached repository.
  static void reset() {
    _journalRepository = CachedRepository(JournalRepositoryImpl());
  }
}
