// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentAdapter extends TypeAdapter<Student> {
  @override
  final int typeId = 0;

  @override
  Student read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Student(
      name: fields[0] as String,
      className: fields[1] as String,
      school: fields[2] as String,
      guardianPhone: fields[3] as String,
      studentPhone: fields[4] as String?,
      address: fields[5] as String,
      dob: fields[6] as DateTime,
      version: fields[7] as String,
      subjects: (fields[8] as List).cast<String>(),
      fees: fields[9] as double,
      photoPath: fields[10] as String?,
      admissionDate: fields[11] as DateTime?,
      paidMonthsByYear: (fields[12] as Map?)?.map((k, v) => MapEntry(k as int, (v as List).cast<int>().toSet())) ?? {},
      paidAmountByYearMonth: (fields[13] as Map?)?.map((k, v) => MapEntry(k as int, (v as Map).map((mk, mv) => MapEntry(mk as int, mv as double)))) ?? {},
      customFeeByYearMonth: (fields[14] as Map?)?.map((k, v) => MapEntry(k as int, (v as Map).map((mk, mv) => MapEntry(mk as int, mv as double)))) ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.className)
      ..writeByte(2)
      ..write(obj.school)
      ..writeByte(3)
      ..write(obj.guardianPhone)
      ..writeByte(4)
      ..write(obj.studentPhone)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.dob)
      ..writeByte(7)
      ..write(obj.version)
      ..writeByte(8)
      ..write(obj.subjects)
      ..writeByte(9)
      ..write(obj.fees)
      ..writeByte(10)
      ..write(obj.photoPath)
      ..writeByte(11)
      ..write(obj.admissionDate)
      ..writeByte(12)
      ..write(obj.paidMonthsByYear.map((k, v) => MapEntry(k, v.toList())))
      ..writeByte(13)
      ..write(obj.paidAmountByYearMonth)
      ..writeByte(14)
      ..write(obj.customFeeByYearMonth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
