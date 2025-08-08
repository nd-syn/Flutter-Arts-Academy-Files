import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/models/fee_model.dart';
import 'package:arts_academy/models/export_data.dart';
import 'package:arts_academy/models/import_result.dart';
import 'package:arts_academy/services/database_helper.dart';

class DataImportExportService {
  final DatabaseHelper _databaseHelper;

  DataImportExportService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Exports all data (students and fees) to a JSON file
  Future<File> exportData() async {
    try {
      // Request storage permissions
      await _requestStoragePermissions();

      // Get all data from database
      final students = await _databaseHelper.getAllStudents();
      final fees = await _databaseHelper.getFees();

      // Create ExportData with new wrapper format
      final exportData = ExportData.create(
        students: students,
        fees: fees,
        appVersion: '1.0.0',
        schema: 1,
      );

      // Convert to JSON string with proper formatting
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData.toJson());

      // Get export directory and create file
      final file = await _createExportFile();

      // Write data to file
      await file.writeAsString(jsonString);

      return file;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Imports data from a JSON file
  Future<ImportResult> importData(String path) async {
    try {
      // Check if file exists
      final file = File(path);
      if (!await file.exists()) {
        return ImportResult.error(
          message: 'Import file not found at path: $path',
        );
      }

      // Read and parse JSON data
      final jsonString = await file.readAsString();
      Map<String, dynamic> importData;
      
      try {
        importData = jsonDecode(jsonString);
      } catch (e) {
        return ImportResult.error(
          message: 'Invalid JSON format in import file',
          errors: ['JSON parsing error: $e'],
        );
      }

      // Check if this is the new format with meta wrapper or old format
      List<dynamic> students;
      List<dynamic> fees;
      
      if (importData.containsKey('meta')) {
        // New format with ExportData wrapper
        try {
          final exportData = ExportData.fromJson(importData);
          students = exportData.students.map((s) => s.toMap()).toList();
          fees = exportData.fees.map((f) => f.toMap()).toList();
        } catch (e) {
          return ImportResult.error(
            message: 'Invalid new format in import file',
            errors: ['New format parsing error: $e'],
          );
        }
      } else {
        // Old format - validate and extract directly
        final validationErrors = _validateImportData(importData);
        if (validationErrors.isNotEmpty) {
          return ImportResult.error(
            message: 'Invalid data format in import file',
            errors: validationErrors,
          );
        }
        students = importData['students'] as List<dynamic>;
        fees = importData['fees'] as List<dynamic>;
      }

      int importedStudentCount = 0;
      int importedFeeCount = 0;
      List<String> importErrors = [];

      // Import students
      for (final studentData in students) {
        try {
          final student = Student.fromMap(studentData as Map<String, dynamic>);
          await _databaseHelper.insertStudent(student);
          importedStudentCount++;
        } catch (e) {
          importErrors.add('Failed to import student: $e');
        }
      }

      // Import fees
      for (final feeData in fees) {
        try {
          final fee = Fee.fromMap(feeData as Map<String, dynamic>);
          await _databaseHelper.insertFee(fee);
          importedFeeCount++;
        } catch (e) {
          importErrors.add('Failed to import fee: $e');
        }
      }

      // Return result
      if (importErrors.isEmpty) {
        return ImportResult.success(
          message: 'Data imported successfully',
          importedStudents: importedStudentCount,
          importedFees: importedFeeCount,
        );
      } else {
        return ImportResult(
          success: importedStudentCount > 0 || importedFeeCount > 0,
          message: importErrors.isEmpty 
              ? 'Data imported successfully'
              : 'Data imported with some errors',
          importedStudents: importedStudentCount,
          importedFees: importedFeeCount,
          errors: importErrors,
        );
      }
    } catch (e) {
      return ImportResult.error(
        message: 'Failed to import data: $e',
      );
    }
  }

  /// Requests necessary storage permissions
  Future<void> _requestStoragePermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need different permissions
      final androidInfo = await _getAndroidVersion();
      
      if (androidInfo >= 33) {
        // For Android 13+, request specific media permissions
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];
        
        for (final permission in permissions) {
          final status = await permission.status;
          if (status.isDenied || status.isPermanentlyDenied) {
            await permission.request();
          }
        }
      } else {
        // For older Android versions, request storage permission
        final permission = Permission.storage;
        final status = await permission.status;
        
        if (status.isDenied || status.isPermanentlyDenied) {
          final result = await permission.request();
          if (!result.isGranted) {
            throw Exception('Storage permission is required for data export/import');
          }
        }
      }
    }
    // iOS doesn't require explicit permissions for app's document directory
  }

  /// Gets Android SDK version
  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      // This is a simplified version. In a real app, you might use
      // device_info_plus package to get actual Android version
      return 33; // Assume Android 13+ for now
    }
    return 0;
  }

  /// Creates the export file in the appropriate directory
  Future<File> _createExportFile() async {
    Directory directory;
    
    if (Platform.isAndroid) {
      // For Android, try to use Downloads directory
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback to external storage directory
        directory = await getExternalStorageDirectory() ?? 
                   await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      // For iOS, use documents directory
      directory = await getApplicationDocumentsDirectory();
    } else {
      // For other platforms, use documents directory
      directory = await getApplicationDocumentsDirectory();
    }

    // Create filename with timestamp
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'arts_academy_export_$timestamp.json';
    
    return File('${directory.path}/$fileName');
  }

  /// Validates the structure of import data
  List<String> _validateImportData(Map<String, dynamic> data) {
    final errors = <String>[];

    // Check for required top-level keys
    if (!data.containsKey('students')) {
      errors.add('Missing "students" data in import file');
    }

    if (!data.containsKey('fees')) {
      errors.add('Missing "fees" data in import file');
    }

    // Validate students data
    if (data.containsKey('students')) {
      final students = data['students'];
      if (students is! List) {
        errors.add('Students data must be a list');
      } else {
        for (int i = 0; i < students.length; i++) {
          final student = students[i];
          if (student is! Map<String, dynamic>) {
            errors.add('Student at index $i must be a map');
            continue;
          }

          // Check required student fields
          final requiredFields = ['name', 'class', 'school', 'version', 
                                'guardian_name', 'guardian_phone', 'subjects', 
                                'fees', 'address', 'admission_date', 'dob'];
          
          for (final field in requiredFields) {
            if (!student.containsKey(field)) {
              errors.add('Student at index $i missing required field: $field');
            }
          }
        }
      }
    }

    // Validate fees data
    if (data.containsKey('fees')) {
      final fees = data['fees'];
      if (fees is! List) {
        errors.add('Fees data must be a list');
      } else {
        for (int i = 0; i < fees.length; i++) {
          final fee = fees[i];
          if (fee is! Map<String, dynamic>) {
            errors.add('Fee at index $i must be a map');
            continue;
          }

          // Check required fee fields
          final requiredFields = ['student_id', 'amount', 'payment_date', 
                                'payment_month', 'payment_year', 'payment_status'];
          
          for (final field in requiredFields) {
            if (!fee.containsKey(field)) {
              errors.add('Fee at index $i missing required field: $field');
            }
          }
        }
      }
    }

    return errors;
  }

  /// Gets the export directory path for display purposes
  Future<String> getExportDirectoryPath() async {
    if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory.path;
      }
      final fallbackDir = await getExternalStorageDirectory() ?? 
                         await getApplicationDocumentsDirectory();
      return fallbackDir.path;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }
}
