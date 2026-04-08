// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsDtoAdapter extends TypeAdapter<SettingsDto> {
  @override
  final int typeId = 2;

  @override
  SettingsDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsDto(
      showNames: fields[0] as bool,
      expandTags: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsDto obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.showNames)
      ..writeByte(1)
      ..write(obj.expandTags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
