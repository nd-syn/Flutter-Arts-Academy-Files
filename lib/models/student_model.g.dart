// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_model.dart';

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
      id: fields[0] as int?,
      name: fields[1] as String,
      studentClass: fields[2] as String,
      school: fields[3] as String,
      version: fields[4] as String,
      guardianName: fields[5] as String,
      guardianPhone: fields[6] as String,
      studentPhone: fields[7] as String?,
      subjects: (fields[8] as List).cast<String>(),
      fees: fields[9] as double,
      address: fields[10] as String,
      admissionDate: fields[11] as DateTime,
      dob: fields[12] as DateTime,
      profilePic: fields[13] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.studentClass)
      ..writeByte(3)
      ..write(obj.school)
      ..writeByte(4)
      ..write(obj.version)
      ..writeByte(5)
      ..write(obj.guardianName)
      ..writeByte(6)
      ..write(obj.guardianPhone)
      ..writeByte(7)
      ..write(obj.studentPhone)
      ..writeByte(8)
      ..write(obj.subjects)
      ..writeByte(9)
      ..write(obj.fees)
      ..writeByte(10)
      ..write(obj.address)
      ..writeByte(11)
      ..write(obj.admissionDate)
      ..writeByte(12)
      ..write(obj.dob)
      ..writeByte(13)
      ..write(obj.profilePic);
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
