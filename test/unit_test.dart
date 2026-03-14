import 'package:flutter_test/flutter_test.dart';
import 'package:reflectly_ai/features/journal_entry/domain/entities/mood.dart';

void main() {
  group('Mood Tests', () {
    test('Mood enum should have correct properties', () {
      final happyMood = Mood.happy;
      expect(happyMood.emoji, '😊');
      expect(happyMood.label, 'Happy');
    });

    test('Mood.fromString should return correct mood', () {
      expect(Mood.fromString('happy'), Mood.happy);
      expect(Mood.fromString('Happy'), Mood.happy);
      expect(Mood.fromString('unknown'), Mood.calm); // default
    });

    test('All moods should have valid emoji and label', () {
      for (final mood in Mood.values) {
        expect(mood.emoji.isNotEmpty, true);
        expect(mood.label.isNotEmpty, true);
      }
    });
  });
}
