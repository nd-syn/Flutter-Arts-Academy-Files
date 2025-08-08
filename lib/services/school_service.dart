import 'package:arts_academy/models/school_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SchoolService {
  static final SchoolService instance = SchoolService._privateConstructor();
  static const String schoolsBoxName = 'schools';
  
  Box<School>? _schoolsBox;
  int _schoolIdCounter = 1;

  SchoolService._privateConstructor();

  Future<void> initSchoolService() async {
    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SchoolAdapter());
    }
    
    // Open box
    _schoolsBox = await Hive.openBox<School>(schoolsBoxName);
    
    // Initialize counter
    _initializeCounter();
    
    // Add default schools if box is empty
    if (_schoolsBox!.isEmpty) {
      await _addDefaultSchools();
    }
  }
  
  void _initializeCounter() {
    if (_schoolsBox!.isNotEmpty) {
      final maxSchoolId = _schoolsBox!.values
          .where((school) => school.id != null)
          .map((school) => school.id!)
          .fold(0, (max, current) => current > max ? current : max);
      _schoolIdCounter = maxSchoolId + 1;
    }
  }
  
  Future<void> _addDefaultSchools() async {
    final defaultSchools = ['BMHS', 'CMS', 'RKS'];
    final now = DateTime.now();
    
    for (final schoolName in defaultSchools) {
      await addSchool(schoolName);
    }
  }
  
  Box<School> get _schools {
    if (_schoolsBox == null) {
      throw Exception('SchoolService not initialized. Call initSchoolService() first.');
    }
    return _schoolsBox!;
  }

  // School CRUD operations
  Future<int> addSchool(String name) async {
    // Check if school already exists
    final existingSchool = _schools.values.firstWhere(
      (school) => school.name.toLowerCase() == name.toLowerCase() && school.isActive,
      orElse: () => School(name: '', createdAt: DateTime.now()),
    );
    
    if (existingSchool.name.isNotEmpty) {
      throw Exception('School with this name already exists');
    }
    
    final school = School(
      id: _schoolIdCounter++,
      name: name.trim(),
      createdAt: DateTime.now(),
      isActive: true,
    );
    
    await _schools.add(school);
    return school.id!;
  }

  Future<List<School>> getAllSchools() async {
    return _schools.values.where((school) => school.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  
  Future<List<String>> getSchoolNames() async {
    final schools = await getAllSchools();
    return schools.map((school) => school.name).toList();
  }

  Future<School?> getSchool(int id) async {
    try {
      return _schools.values.firstWhere((school) => school.id == id && school.isActive);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateSchool(int id, String newName) async {
    // Check if another school with the same name exists
    final existingSchool = _schools.values.firstWhere(
      (school) => school.name.toLowerCase() == newName.toLowerCase() && 
                  school.isActive && 
                  school.id != id,
      orElse: () => School(name: '', createdAt: DateTime.now()),
    );
    
    if (existingSchool.name.isNotEmpty) {
      throw Exception('Another school with this name already exists');
    }
    
    final index = _schools.values.toList().indexWhere((s) => s.id == id && s.isActive);
    if (index != -1) {
      final school = _schools.getAt(index)!;
      final updatedSchool = school.copyWith(name: newName.trim());
      await _schools.putAt(index, updatedSchool);
      return true;
    }
    return false;
  }

  Future<bool> deleteSchool(int id) async {
    final index = _schools.values.toList().indexWhere((s) => s.id == id && s.isActive);
    if (index != -1) {
      final school = _schools.getAt(index)!;
      final updatedSchool = school.copyWith(isActive: false);
      await _schools.putAt(index, updatedSchool);
      return true;
    }
    return false;
  }

  /// Permanently delete a school (for cleanup)
  Future<bool> permanentDeleteSchool(int id) async {
    final index = _schools.values.toList().indexWhere((s) => s.id == id);
    if (index != -1) {
      await _schools.deleteAt(index);
      return true;
    }
    return false;
  }

  /// Check if a school name is being used by any students
  Future<bool> isSchoolInUse(String schoolName) async {
    // This would need to be implemented by checking students
    // For now, we'll assume it's not in use
    return false;
  }

  /// Bulk operations for import/export
  Future<void> insertBulkSchools(List<School> schools) async {
    for (final school in schools) {
      await _schools.add(school);
    }
  }

  /// Clear all schools (for data reset)
  Future<void> clearAllSchools() async {
    await _schoolsBox?.close();
    await Hive.deleteBoxFromDisk(schoolsBoxName);
    _schoolsBox = await Hive.openBox<School>(schoolsBoxName);
    _schoolIdCounter = 1;
    await _addDefaultSchools();
  }

  /// Set the internal ID counter
  void setCounter(int maxId) {
    _schoolIdCounter = maxId + 1;
  }
}
