import 'dart:convert';
import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'student_model.g.dart';

@HiveType(typeId: 0)
class Student extends HiveObject {
  @HiveField(0)
  final int? id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String studentClass;
  
  @HiveField(3)
  final String school;
  
  @HiveField(4)
  final String version;
  
  @HiveField(5)
  final String guardianName;
  
  @HiveField(6)
  final String guardianPhone;
  
  @HiveField(7)
  final String? studentPhone;
  
  @HiveField(8)
  final List<String> subjects;
  
  @HiveField(9)
  final double fees;
  
  @HiveField(10)
  final String address;
  
  @HiveField(11)
  final DateTime admissionDate;
  
  @HiveField(12)
  final DateTime dob;
  
  @HiveField(13)
  final Uint8List? profilePic;

  Student({
    this.id,
    required this.name,
    required this.studentClass,
    required this.school,
    required this.version,
    required this.guardianName,
    required this.guardianPhone,
    this.studentPhone,
    required this.subjects,
    required this.fees,
    required this.address,
    required this.admissionDate,
    required this.dob,
    this.profilePic,
  });

  // Create a copy of the student with updated fields
  Student copyWith({
    int? id,
    String? name,
    String? studentClass,
    String? school,
    String? version,
    String? guardianName,
    String? guardianPhone,
    String? studentPhone,
    List<String>? subjects,
    double? fees,
    String? address,
    DateTime? admissionDate,
    DateTime? dob,
    Uint8List? profilePic,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      studentClass: studentClass ?? this.studentClass,
      school: school ?? this.school,
      version: version ?? this.version,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      studentPhone: studentPhone ?? this.studentPhone,
      subjects: subjects ?? this.subjects,
      fees: fees ?? this.fees,
      address: address ?? this.address,
      admissionDate: admissionDate ?? this.admissionDate,
      dob: dob ?? this.dob,
      profilePic: profilePic ?? this.profilePic,
    );
  }

  // Convert Student object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'class': studentClass,
      'school': school,
      'version': version,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
      'student_phone': studentPhone,
      'subjects': jsonEncode(subjects),
      'fees': fees,
      'address': address,
      'admission_date': admissionDate.toIso8601String(),
      'dob': dob.toIso8601String(),
      'profile_pic': profilePic != null ? base64Encode(profilePic!) : null,
    };
  }

  // Create a Student object from a Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      studentClass: map['class'],
      school: map['school'],
      version: map['version'],
      guardianName: map['guardian_name'],
      guardianPhone: map['guardian_phone'],
      studentPhone: map['student_phone'],
      subjects: List<String>.from(jsonDecode(map['subjects'])),
      fees: map['fees'],
      address: map['address'],
      admissionDate: DateTime.parse(map['admission_date']),
      dob: DateTime.parse(map['dob']),
      profilePic: map['profile_pic'] != null ? base64Decode(map['profile_pic']) : null,
    );
  }

  // Convert Student object to JSON format
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // Create a Student object from JSON
  static Student fromJson(Map<String, dynamic> json) {
    return Student.fromMap(json);
  }

  @override
  String toString() {
    return 'Student(id: $id, name: $name, class: $studentClass, school: $school, version: $version, guardianName: $guardianName, guardianPhone: $guardianPhone, studentPhone: $studentPhone, subjects: $subjects, fees: $fees, address: $address, admissionDate: $admissionDate, dob: $dob, profilePic: $profilePic)';
  }
}
