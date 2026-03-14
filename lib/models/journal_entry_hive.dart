import 'package:hive/hive.dart';

part 'journal_entry_hive.g.dart';

@HiveType(typeId: 0)
class JournalEntryHive extends HiveObject {
  @HiveField(0)
  late int id;
  
  @HiveField(1)
  late String text;
  
  @HiveField(2)
  late String mood;
  
  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  List<String> tags = [];
  
  JournalEntryHive({
    required this.id,
    required this.text,
    required this.mood,
    required this.timestamp,
    this.tags = const [],
  });

  // Constructor for creating a new entry with current timestamp
  JournalEntryHive.create({
    required this.text,
    required this.mood,
    this.tags = const [],
  }) : timestamp = DateTime.now(), id = 0;
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
