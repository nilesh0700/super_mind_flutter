// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_content.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SharedContentAdapter extends TypeAdapter<SharedContent> {
  @override
  final int typeId = 0;

  @override
  SharedContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SharedContent(
      text: fields[0] as String?,
      imageUris: (fields[1] as List?)?.cast<String>(),
      timestamp: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SharedContent obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.imageUris)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
