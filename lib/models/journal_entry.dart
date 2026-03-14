import 'package:isar/isar.dart';

part 'journal_entry.g.dart';

@Collection()
class JournalEntry {
  Id id = Isar.autoIncrement;
  
  late String text;
  
  late String mood;
  
  late DateTime timestamp;
  
  JournalEntry({
    required this.text,
    required this.mood,
    required this.timestamp,
  });

  // Constructor for creating a new entry with current timestamp
  JournalEntry.create({
    required this.text,
    required this.mood,
  }) : timestamp = DateTime.now();

  // Helper method to get formatted date
  String get formattedDate {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
  }

  // Helper method to get formatted time
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to get full formatted datetime
  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }
}
