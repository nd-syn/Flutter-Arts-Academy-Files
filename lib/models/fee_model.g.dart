// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeeAdapter extends TypeAdapter<Fee> {
  @override
  final int typeId = 1;

  @override
  Fee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Fee(
      id: fields[0] as int?,
      studentId: fields[1] as int,
      amount: fields[2] as double,
      paymentDate: fields[3] as DateTime,
      paymentMonth: fields[4] as int,
      paymentYear: fields[5] as int,
      paymentStatus: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Fee obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.paymentDate)
      ..writeByte(4)
      ..write(obj.paymentMonth)
      ..writeByte(5)
      ..write(obj.paymentYear)
      ..writeByte(6)
      ..write(obj.paymentStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
