// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoDtoAdapter extends TypeAdapter<VideoDto> {
  @override
  final int typeId = 1;

  @override
  VideoDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoDto(
      id: fields[0] as String,
      assetId: fields[1] as String,
      name: fields[2] as String,
      tagIds: (fields[3] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, VideoDto obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.assetId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.tagIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
