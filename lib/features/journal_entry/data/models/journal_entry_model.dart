// Temporary fix: Comment out Isar imports
// import 'package:isar/isar.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/mood.dart';

// part 'journal_entry_model.g.dart';

// @Collection()
class JournalEntryModel {
  // Id id = Isar.autoIncrement;
  late int id;
  
  late String content;
  
  late String mood;
  
  late DateTime createdAt;
  
  // @Index()
  List<String> tags = [];
  
  JournalEntryModel({
    required this.content,
    required this.mood,
    required this.createdAt,
    this.tags = const [],
  });

  JournalEntryModel.create({
    required this.content,
    required this.mood,
    this.tags = const [],
  }) : createdAt = DateTime.now(), id = DateTime.now().millisecondsSinceEpoch;

  JournalEntryEntity toEntity() {
    return JournalEntryEntity(
      id: id, // id == Isar.autoIncrement ? null : id,
      text: content,
      mood: Mood.fromString(mood),
      timestamp: createdAt,
    );
  }

  static JournalEntryModel fromEntity(JournalEntryEntity entity) {
    return JournalEntryModel(
      content: entity.text,
      mood: entity.mood.label,
      createdAt: entity.timestamp,
      tags: [], // TODO: Add tags to entity when needed
    )..id = entity.id ?? DateTime.now().millisecondsSinceEpoch; // ..id = entity.id ?? Isar.autoIncrement;
  }
}
