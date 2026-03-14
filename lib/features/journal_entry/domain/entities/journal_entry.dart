import 'mood.dart';

class JournalEntryEntity {
  final int? id;
  final String text;
  final Mood mood;
  final DateTime timestamp;
  final List<String> tags;

  const JournalEntryEntity({
    this.id,
    required this.text,
    required this.mood,
    required this.timestamp,
    this.tags = const [],
  });

  JournalEntryEntity copyWith({
    int? id,
    String? text,
    Mood? mood,
    DateTime? timestamp,
    List<String>? tags,
  }) {
    return JournalEntryEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      timestamp: timestamp ?? this.timestamp,
      tags: tags ?? this.tags,
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
        other.timestamp == timestamp &&
        _listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return id.hashCode ^ text.hashCode ^ mood.hashCode ^ timestamp.hashCode ^ tags.hashCode;
  }

  bool _listEquals(List<Object> a, List<Object> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'JournalEntryEntity(id: $id, text: $text, mood: $mood, timestamp: $timestamp)';
  }
}
