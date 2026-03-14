import 'mood.dart';

class JournalEntryEntity {
  final int? id;
  final String text;
  final Mood mood;
  final DateTime timestamp;

  const JournalEntryEntity({
    this.id,
    required this.text,
    required this.mood,
    required this.timestamp,
  });

  JournalEntryEntity copyWith({
    int? id,
    String? text,
    Mood? mood,
    DateTime? timestamp,
  }) {
    return JournalEntryEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  String get formattedDate {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntryEntity &&
        other.id == id &&
        other.text == text &&
        other.mood == mood &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^ text.hashCode ^ mood.hashCode ^ timestamp.hashCode;
  }

  @override
  String toString() {
    return 'JournalEntryEntity(id: $id, text: $text, mood: $mood, timestamp: $timestamp)';
  }
}
