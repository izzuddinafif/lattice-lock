// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_ink_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomInkDefinitionAdapter extends TypeAdapter<CustomInkDefinition> {
  @override
  final int typeId = 100;

  @override
  CustomInkDefinition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomInkDefinition()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..code = fields[2] as String
      ..colorValue = fields[3] as int
      ..roleName = fields[4] as String
      ..hexValue = fields[5] as int;
  }

  @override
  void write(BinaryWriter writer, CustomInkDefinition obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.roleName)
      ..writeByte(5)
      ..write(obj.hexValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomInkDefinitionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomMaterialProfileAdapter extends TypeAdapter<CustomMaterialProfile> {
  @override
  final int typeId = 101;

  @override
  CustomMaterialProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomMaterialProfile()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..inks = (fields[2] as List).cast<CustomInkDefinition>()
      ..createdAt = fields[3] as DateTime
      ..modifiedAt = fields[4] as DateTime
      ..isActive = fields[5] as bool;
  }

  @override
  void write(BinaryWriter writer, CustomMaterialProfile obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.inks)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.modifiedAt)
      ..writeByte(5)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomMaterialProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
