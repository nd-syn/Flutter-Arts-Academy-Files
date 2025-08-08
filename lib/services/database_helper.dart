import 'dart:async';
import 'package:arts_academy/models/fee_model.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static const String studentsBoxName = 'students';
  static const String feesBoxName = 'fees';
  
  Box<Student>? _studentsBox;
  Box<Fee>? _feesBox;
  int _studentIdCounter = 1;
  int _feeIdCounter = 1;

  DatabaseHelper._privateConstructor();

  Future<void> initDatabase() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StudentAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FeeAdapter());
    }
    
    // Open boxes
    _studentsBox = await Hive.openBox<Student>(studentsBoxName);
    _feesBox = await Hive.openBox<Fee>(feesBoxName);
    
    // Initialize counters
    _initializeCounters();
  }
  
  void _initializeCounters() {
    if (_studentsBox!.isNotEmpty) {
      final maxStudentId = _studentsBox!.values
          .where((student) => student.id != null)
          .map((student) => student.id!)
          .fold(0, (max, current) => current > max ? current : max);
      _studentIdCounter = maxStudentId + 1;
    }
    
    if (_feesBox!.isNotEmpty) {
      final maxFeeId = _feesBox!.values
          .where((fee) => fee.id != null)
          .map((fee) => fee.id!)
          .fold(0, (max, current) => current > max ? current : max);
      _feeIdCounter = maxFeeId + 1;
    }
  }
  
  Box<Student> get _students => _studentsBox!;
  Box<Fee> get _fees => _feesBox!;

  // Student CRUD operations
  Future<int> insertStudent(Student student) async {
    final studentWithId = Student(
      id: _studentIdCounter++,
      name: student.name,
      studentClass: student.studentClass,
      school: student.school,
      version: student.version,
      guardianName: student.guardianName,
      guardianPhone: student.guardianPhone,
      studentPhone: student.studentPhone,
      subjects: student.subjects,
      fees: student.fees,
      address: student.address,
      admissionDate: student.admissionDate,
      dob: student.dob,
      profilePic: student.profilePic,
    );
    
    await _students.add(studentWithId);
    return studentWithId.id!;
  }

  Future<List<Student>> getStudents() async {
    return _students.values.toList();
  }
  
  // Alias for getStudents to maintain compatibility
  Future<List<Student>> getAllStudents() async {
    return getStudents();
  }

  Future<Student?> getStudent(int id) async {
    try {
      return _students.values.firstWhere((student) => student.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateStudent(Student student) async {
    final index = _students.values.toList().indexWhere((s) => s.id == student.id);
    if (index != -1) {
      await _students.putAt(index, student);
      return 1; // Return 1 to indicate success (like SQLite)
    }
    return 0; // Return 0 to indicate no rows affected
  }

  Future<int> deleteStudent(int id) async {
    final index = _students.values.toList().indexWhere((s) => s.id == id);
    if (index != -1) {
      await _students.deleteAt(index);
      // Also delete all fees for this student
      final feesToDelete = _fees.values.where((fee) => fee.studentId == id).toList();
      for (final fee in feesToDelete) {
        final feeIndex = _fees.values.toList().indexOf(fee);
        if (feeIndex != -1) {
          await _fees.deleteAt(feeIndex);
        }
      }
      return 1; // Return 1 to indicate success
    }
    return 0; // Return 0 to indicate no rows affected
  }

  // Fee CRUD operations
  Future<int> insertFee(Fee fee) async {
    final feeWithId = Fee(
      id: _feeIdCounter++,
      studentId: fee.studentId,
      amount: fee.amount,
      paymentDate: fee.paymentDate,
      paymentMonth: fee.paymentMonth,
      paymentYear: fee.paymentYear,
      paymentStatus: fee.paymentStatus,
    );
    
    await _fees.add(feeWithId);
    return feeWithId.id!;
  }

  Future<List<Fee>> getFees() async {
    return _fees.values.toList();
  }

  Future<List<Fee>> getStudentFees(int studentId) async {
    return _fees.values.where((fee) => fee.studentId == studentId).toList();
  }
  
  // Alias for getStudentFees to maintain compatibility
  Future<List<Fee>> getFeesForStudent(int studentId) async {
    return getStudentFees(studentId);
  }

  Future<int> updateFee(Fee fee) async {
    final index = _fees.values.toList().indexWhere((f) => f.id == fee.id);
    if (index != -1) {
      await _fees.putAt(index, fee);
      return 1; // Return 1 to indicate success
    }
    return 0; // Return 0 to indicate no rows affected
  }

  Future<int> deleteFee(int id) async {
    final index = _fees.values.toList().indexWhere((f) => f.id == id);
    if (index != -1) {
      await _fees.deleteAt(index);
      return 1; // Return 1 to indicate success
    }
    return 0; // Return 0 to indicate no rows affected
  }

  // Bulk operations
  
  /// Clears all data from the database.
  /// Closes boxes, deletes them, reopens, and resets internal counters.
  Future<void> clearAllData() async {
    // Close boxes
    await _studentsBox?.close();
    await _feesBox?.close();
    
    // Delete the boxes (this clears all data)
    await Hive.deleteBoxFromDisk(studentsBoxName);
    await Hive.deleteBoxFromDisk(feesBoxName);
    
    // Reopen the boxes
    _studentsBox = await Hive.openBox<Student>(studentsBoxName);
    _feesBox = await Hive.openBox<Fee>(feesBoxName);
    
    // Reset internal counters
    _studentIdCounter = 1;
    _feeIdCounter = 1;
  }
  
  /// Inserts multiple students in bulk without changing their IDs.
  /// The students should already have their IDs set.
  Future<void> insertBulkStudents(List<Student> students) async {
    for (final student in students) {
      await _students.add(student);
    }
  }
  
  /// Inserts multiple fees in bulk without changing their IDs.
  /// The fees should already have their IDs set.
  Future<void> insertBulkFees(List<Fee> fees) async {
    for (final fee in fees) {
      await _fees.add(fee);
    }
  }
  
  /// Sets the internal ID counters to specific values.
  /// This is useful after importing data to ensure new records get proper IDs.
  void setCounters({required int studentMaxId, required int feeMaxId}) {
    _studentIdCounter = studentMaxId + 1;
    _feeIdCounter = feeMaxId + 1;
  }
}
