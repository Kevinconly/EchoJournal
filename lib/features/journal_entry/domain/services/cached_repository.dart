import 'dart:async';
import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class CachedRepository implements JournalRepository {
  final JournalRepository _repository;
  final Map<String, List<JournalEntryEntity>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheTimeout = const Duration(minutes: 5);

  CachedRepository(this._repository);

  @override
  Future<List<JournalEntryEntity>> getAllEntries() async {
    final cacheKey = 'all_entries';
    final now = DateTime.now();
    
    // Return cached data if valid
    if (_cache.containsKey(cacheKey) && 
        now.difference(_cacheTimestamps[cacheKey]!).inDuration(_cacheTimeout).inMinutes < _cacheTimeout.inMinutes) {
      return _cache[cacheKey]!;
    }
    
    // Fetch fresh data
    try {
      final entries = await _repository.getAllEntries();
      _cache[cacheKey] = entries;
      _cacheTimestamps[cacheKey] = now;
      return entries;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveEntry(JournalEntryEntity entry) async {
    try {
      await _repository.saveEntry(entry);
      _invalidateCache();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteEntry(int id) async {
    try {
      await _repository.deleteEntry(id);
      _invalidateCache();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteAllEntries() async {
    try {
      await _repository.deleteAllEntries();
      _invalidateCache();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<JournalEntryEntity>> getEntriesByMood(String mood) async {
    final cacheKey = 'entries_by_mood_$mood';
    final now = DateTime.now();
    
    // Return cached data if valid
    if (_cache.containsKey(cacheKey) && 
        now.difference(_cacheTimestamps[cacheKey]!).inDuration(_cacheTimeout).inMinutes < _cacheTimeout.inMinutes) {
      return _cache[cacheKey]!;
    }
    
    // Fetch fresh data
    try {
      final entries = await _repository.getEntriesByMood(mood);
      _cache[cacheKey] = entries;
      _cacheTimestamps[cacheKey] = now;
      return entries;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<JournalEntryEntity>> getEntriesByDateRange(DateTime startDate, DateTime endDate) async {
    final cacheKey = 'entries_by_date_range_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';
    final now = DateTime.now();
    
    // Return cached data if valid
    if (_cache.containsKey(cacheKey) && 
        now.difference(_cacheTimestamps[cacheKey]!).inDuration(_cacheTimeout).inMinutes < _cacheTimeout.inMinutes) {
      return _cache[cacheKey]!;
    }
    
    // Fetch fresh data
    try {
      final entries = await _repository.getEntriesByDateRange(startDate, endDate);
      _cache[cacheKey] = entries;
      _cacheTimestamps[cacheKey] = now;
      return entries;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<JournalEntryEntity>> searchEntries(String query) async {
    final cacheKey = 'search_entries_$query';
    final now = DateTime.now();
    
    // Return cached data if valid
    if (_cache.containsKey(cacheKey) && 
        now.difference(_cacheTimestamps[cacheKey]!).inDuration(_cacheTimeout).inMinutes < _cacheTimeout.inMinutes) {
      return _cache[cacheKey]!;
    }
    
    // Fetch fresh data
    try {
      final entries = await _repository.searchEntries(query);
      _cache[cacheKey] = entries;
      _cacheTimestamps[cacheKey] = now;
      return entries;
    } catch (e) {
      rethrow;
    }
  }

  void _invalidateCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
