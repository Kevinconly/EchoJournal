import 'package:flutter_test/flutter_test.dart';
import 'package:echo_journal/features/journal_entry/domain/entities/journal_entry.dart';
import 'package:echo_journal/features/journal_entry/domain/entities/mood.dart';
import 'package:echo_journal/features/journal_entry/domain/repositories/journal_repository.dart';
import 'package:echo_journal/features/journal_entry/domain/services/cached_repository.dart';

class CountingJournalRepository implements JournalRepository {
  final List<JournalEntryEntity> _storage = [];
  int getAllCalls = 0;
  int searchCalls = 0;
  int idCounter = 1;

  @override
  Future<void> saveEntry(JournalEntryEntity entry) async {
    final toSave = entry.id == null ? entry.copyWith(id: idCounter++) : entry;
    _storage.add(toSave);
  }

  @override
  Future<List<JournalEntryEntity>> getAllEntries() async {
    getAllCalls++;
    return List.from(_storage);
  }

  @override
  Future<JournalEntryEntity?> getEntryById(int id) async {
    try {
      return _storage.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<JournalEntryEntity>> getEntriesByMood(Mood mood) async {
    return _storage.where((e) => e.mood == mood).toList();
  }

  @override
  Future<List<JournalEntryEntity>> getEntriesByDateRange(DateTime start, DateTime end) async {
    return _storage.where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end)).toList();
  }

  @override
  Future<void> updateEntry(JournalEntryEntity entry) async {
    final idx = _storage.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _storage[idx] = entry;
    }
  }

  @override
  Future<void> deleteEntry(int id) async {
    _storage.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> deleteAllEntries() async {
    _storage.clear();
  }

  @override
  Future<int> getEntryCount() async => _storage.length;

  @override
  Future<List<JournalEntryEntity>> searchEntries(String query) async {
    searchCalls++;
    final q = query.toLowerCase();
    return _storage.where((e) => e.text.toLowerCase().contains(q)).toList();
  }
}

void main() {
  group('CachedRepository Invalidation and Synchronization Tests', () {
    late CountingJournalRepository underlyingRepo;
    late CachedRepository cachedRepo;

    setUp(() {
      underlyingRepo = CountingJournalRepository();
      cachedRepo = CachedRepository(underlyingRepo);
    });

    test('getAllEntries caches results on consecutive calls', () async {
      await underlyingRepo.saveEntry(JournalEntryEntity(
        text: 'First entry',
        mood: Mood.calm,
        timestamp: DateTime.now(),
      ));

      final firstCall = await cachedRepo.getAllEntries();
      expect(firstCall.length, 1);
      expect(underlyingRepo.getAllCalls, 1);

      final secondCall = await cachedRepo.getAllEntries();
      expect(secondCall.length, 1);
      expect(underlyingRepo.getAllCalls, 1); // Served from cache!
    });

    test('saveEntry invalidates cached entries', () async {
      await cachedRepo.getAllEntries();
      expect(underlyingRepo.getAllCalls, 1);

      await cachedRepo.saveEntry(JournalEntryEntity(
        text: 'New entry',
        mood: Mood.happy,
        timestamp: DateTime.now(),
      ));

      // Next fetch must query underlying repo
      await cachedRepo.getAllEntries();
      expect(underlyingRepo.getAllCalls, 2);
    });

    test('updateEntry invalidates cache and updates entry', () async {
      await cachedRepo.saveEntry(JournalEntryEntity(
        id: 1,
        text: 'Original content',
        mood: Mood.sad,
        timestamp: DateTime.now(),
      ));

      final entries = await cachedRepo.getAllEntries();
      expect(entries.first.text, 'Original content');

      await cachedRepo.updateEntry(entries.first.copyWith(
        text: 'Updated content',
        mood: Mood.calm,
      ));

      final refreshed = await cachedRepo.getAllEntries();
      expect(refreshed.first.text, 'Updated content');
      expect(refreshed.first.mood, Mood.calm);
    });

    test('deleteEntry invalidates cache and removes entry', () async {
      await cachedRepo.saveEntry(JournalEntryEntity(
        id: 1,
        text: 'To be deleted',
        mood: Mood.stressed,
        timestamp: DateTime.now(),
      ));

      var entries = await cachedRepo.getAllEntries();
      expect(entries.length, 1);

      await cachedRepo.deleteEntry(1);

      entries = await cachedRepo.getAllEntries();
      expect(entries.isEmpty, isTrue);
    });

    test('deleteAllEntries cleans cache and storage', () async {
      await cachedRepo.saveEntry(JournalEntryEntity(text: 'E1', mood: Mood.happy, timestamp: DateTime.now()));
      await cachedRepo.saveEntry(JournalEntryEntity(text: 'E2', mood: Mood.calm, timestamp: DateTime.now()));

      expect(await cachedRepo.getEntryCount(), 2);

      await cachedRepo.deleteAllEntries();

      expect(await cachedRepo.getEntryCount(), 0);
      final entries = await cachedRepo.getAllEntries();
      expect(entries.isEmpty, isTrue);
    });
  });
}
