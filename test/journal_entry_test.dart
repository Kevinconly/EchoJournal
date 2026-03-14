import 'package:flutter_test/flutter_test.dart';
import 'package:reflectly_ai/features/journal_entry/domain/entities/journal_entry.dart';
import 'package:reflectly_ai/features/journal_entry/domain/entities/mood.dart';

void main() {
  group('JournalEntry Tests', () {
    test('JournalEntry should create with required fields', () {
      final now = DateTime.now();
      final entry = JournalEntryEntity(
        id: 1,
        text: 'Test entry',
        mood: Mood.happy,
        timestamp: now,
      );

      expect(entry.id, 1);
      expect(entry.text, 'Test entry');
      expect(entry.mood, Mood.happy);
      expect(entry.timestamp, now);
    });

    test('JournalEntry copyWith should work correctly', () {
      final original = JournalEntryEntity(
        id: 1,
        text: 'Original',
        mood: Mood.happy,
        timestamp: DateTime.now(),
      );

      final updated = original.copyWith(
        text: 'Updated',
        mood: Mood.sad,
      );

      expect(updated.id, original.id);
      expect(updated.text, 'Updated');
      expect(updated.mood, Mood.sad);
      expect(updated.timestamp, original.timestamp);
    });

    test('JournalEntry formatted date should work', () {
      final entry = JournalEntryEntity(
        id: 1,
        text: 'Test',
        mood: Mood.happy,
        timestamp: DateTime(2023, 12, 25, 14, 30),
      );

      expect(entry.formattedDate, '25/12/2023');
      expect(entry.formattedTime, '14:30');
    });
  });
}
