// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TagDtoAdapter extends TypeAdapter<TagDto> {
  @override
  final int typeId = 0;

  @override
  TagDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TagDto(
      id: fields[0] as String,
      name: fields[1] as String,
      color: fields[2] as String,
      order: fields[3] == null ? -1 : fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TagDto obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
