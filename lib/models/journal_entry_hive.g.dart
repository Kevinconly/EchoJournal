// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JournalEntryHiveAdapter extends TypeAdapter<JournalEntryHive> {
  @override
  final int typeId = 0;

  @override
  JournalEntryHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntryHive(
      id: fields[0] as int,
      text: fields[1] as String,
      mood: fields[2] as String,
      timestamp: fields[3] as DateTime,
      tags: (fields[4] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntryHive obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.mood)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntryHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
