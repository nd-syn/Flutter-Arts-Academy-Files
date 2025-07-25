import 'package:hive/hive.dart';
import '../models/student.dart';

class StudentDB {
  static const String boxName = 'students';

  static Future<void> addStudent(Student student) async {
    final box = await Hive.openBox<Student>(boxName);
    await box.add(student);
  }

  static Future<void> updateStudent(int index, Student student) async {
    final box = await Hive.openBox<Student>(boxName);
    await box.putAt(index, student);
  }

  static Future<void> deleteStudent(int index) async {
    final box = await Hive.openBox<Student>(boxName);
    await box.deleteAt(index);
  }

  static Future<List<Student>> getAllStudents() async {
    final box = await Hive.openBox<Student>(boxName);
    return box.values.toList();
  }

  static Future<void> migratePaidMonthsToMultiYear(Box<Student> box) async {
    for (final student in box.values) {
      // If the student has a paidMonths field (legacy), migrate it
      if ((student as dynamic).paidMonths != null) {
        final paidMonths = (student as dynamic).paidMonths as Set<int>;
        final year = student.admissionDate.year;
        student.paidMonthsByYear[year] = paidMonths;
        // Optionally remove the old field if you want
        (student as dynamic).paidMonths = null;
        await student.save();
      }
    }
  }
} 