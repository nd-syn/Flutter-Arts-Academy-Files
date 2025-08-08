import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/fee_model.dart';
import '../models/export_data.dart';
import '../models/import_result.dart';
import 'database_helper.dart';

/// Service for importing data from JSON files
class DataImportService {
  final DatabaseHelper _databaseHelper;

  DataImportService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Step 1 & 2 Combined: Pick file and validate
  Future<ExportData> _pickAndValidateJsonFile() async {
    try {
      // Pick file with data included
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        dialogTitle: 'Select JSON file to import',
        withData: true, // This ensures we get the file data
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('DataImportService: No file selected by user');
        throw Exception('No file selected');
      }

      final pickedFile = result.files.first;
      if (pickedFile.bytes == null) {
        debugPrint('DataImportService: Could not read file data for ${pickedFile.name}');
        throw Exception('Could not read file data. Please check file permissions and try again.');
      }

      // Convert bytes to string
      final fileBytes = pickedFile.bytes!;
      final jsonString = String.fromCharCodes(fileBytes);

      debugPrint('DataImportService: Successfully read file ${pickedFile.name}, size: ${fileBytes.length} bytes');

      // Parse JSON - catch FormatException specifically
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(jsonString);
      } on FormatException catch (e) {
        debugPrint('DataImportService: JSON FormatException - $e');
        throw Exception('Backup file is corrupted or incompatible. Please check the file format.');
      } catch (e) {
        debugPrint('DataImportService: JSON parsing error - $e');
        throw Exception('Invalid JSON format: $e');
      }

      // Validate structure and meta.schema - catch missing keys
      try {
        if (!jsonData.containsKey('meta')) {
          debugPrint('DataImportService: Missing meta field');
          throw Exception('Backup file is corrupted or incompatible. Missing metadata.');
        }

        final meta = jsonData['meta'];
        if (meta is! Map<String, dynamic>) {
          debugPrint('DataImportService: Invalid meta field format');
          throw Exception('Backup file is corrupted or incompatible. Invalid metadata format.');
        }

        if (!meta.containsKey('schema')) {
          debugPrint('DataImportService: Missing schema field in meta');
          throw Exception('Backup file is corrupted or incompatible. Missing schema information.');
        }

        if (meta['schema'] != 1) {
          debugPrint('DataImportService: Unsupported schema version: ${meta['schema']}');
          throw Exception('Backup file is corrupted or incompatible. Unsupported schema version.');
        }

        // Validate presence of arrays
        if (!jsonData.containsKey('students')) {
          debugPrint('DataImportService: Missing students array');
          throw Exception('Backup file is corrupted or incompatible. Missing student data.');
        }

        if (!jsonData.containsKey('fees')) {
          debugPrint('DataImportService: Missing fees array');
          throw Exception('Backup file is corrupted or incompatible. Missing fee data.');
        }

        if (jsonData['students'] is! List) {
          debugPrint('DataImportService: Invalid students field type');
          throw Exception('Backup file is corrupted or incompatible. Invalid student data format.');
        }

        if (jsonData['fees'] is! List) {
          debugPrint('DataImportService: Invalid fees field type');
          throw Exception('Backup file is corrupted or incompatible. Invalid fee data format.');
        }
      } catch (e) {
        debugPrint('DataImportService: Validation error - $e');
        if (e.toString().contains('Backup file is corrupted or incompatible')) {
          rethrow; // Already formatted error message
        }
        throw Exception('Backup file is corrupted or incompatible. $e');
      }

      // Parse into ExportData object
      try {
        final exportData = ExportData.fromJson(jsonData);
        debugPrint('DataImportService: Successfully parsed export data - ${exportData.students.length} students, ${exportData.fees.length} fees');
        return exportData;
      } catch (e) {
        debugPrint('DataImportService: ExportData parsing error - $e');
        throw Exception('Backup file is corrupted or incompatible. Failed to parse data structure.');
      }
    } on Exception {
      rethrow; // Re-throw already formatted exceptions
    } catch (e) {
      debugPrint('DataImportService: Unexpected error in _pickAndValidateJsonFile - $e');
      
      // Check for permission-related errors
      if (e.toString().toLowerCase().contains('permission') || 
          e.toString().toLowerCase().contains('access') ||
          e.toString().toLowerCase().contains('denied')) {
        throw Exception('Permission denied. Please grant file access permission in your device settings and try again.');
      }
      
      throw Exception('Failed to pick and validate JSON file: $e');
    }
  }

  /// Step 3: Show confirmation dialog
  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Import Confirmation'),
          content: const Text(
            'Importing will erase current data. Continue?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Step 4a: Show progress dialog
  void _showProgressDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  /// Step 4c: Convert JSON arrays to Student & Fee objects (handle base64→Uint8List)
  List<Student> _convertJsonToStudents(List<dynamic> studentsJson) {
    return studentsJson.map((studentJson) {
      final studentMap = studentJson as Map<String, dynamic>;
      
      // Handle profile picture base64 conversion
      Uint8List? profilePic;
      if (studentMap['profile_pic'] != null && studentMap['profile_pic'] is String) {
        try {
          profilePic = base64Decode(studentMap['profile_pic'] as String);
        } catch (e) {
          // If base64 decode fails, set to null
          profilePic = null;
        }
      }

      // Create student with converted profile picture
      final student = Student.fromJson(studentMap);
      return student.copyWith(profilePic: profilePic);
    }).toList();
  }

  List<Fee> _convertJsonToFees(List<dynamic> feesJson) {
    return feesJson.map((feeJson) {
      return Fee.fromJson(feeJson as Map<String, dynamic>);
    }).toList();
  }

  /// Create a backup of current Hive data files
  Future<String> _createHiveBackup() async {
    try {
      debugPrint('DataImportService: Creating backup of Hive data files');
      
      // Get temporary directory for backup
      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory('${tempDir.path}/hive_backup_${DateTime.now().millisecondsSinceEpoch}');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      debugPrint('DataImportService: Backup directory created at ${backupDir.path}');
      
      // Get Hive box directory
      final hiveDir = Directory(Hive.box<Student>(DatabaseHelper.studentsBoxName).path!);
      final hiveParentDir = hiveDir.parent;
      
      // Copy students and fees hive files
      final studentsHiveFile = File('${hiveParentDir.path}/${DatabaseHelper.studentsBoxName}.hive');
      final feesHiveFile = File('${hiveParentDir.path}/${DatabaseHelper.feesBoxName}.hive');
      
      if (await studentsHiveFile.exists()) {
        await studentsHiveFile.copy('${backupDir.path}/${DatabaseHelper.studentsBoxName}.hive');
        debugPrint('DataImportService: Backed up students.hive');
      }
      
      if (await feesHiveFile.exists()) {
        await feesHiveFile.copy('${backupDir.path}/${DatabaseHelper.feesBoxName}.hive');
        debugPrint('DataImportService: Backed up fees.hive');
      }
      
      // Also backup any lock files
      final studentsLockFile = File('${hiveParentDir.path}/${DatabaseHelper.studentsBoxName}.lock');
      final feesLockFile = File('${hiveParentDir.path}/${DatabaseHelper.feesBoxName}.lock');
      
      if (await studentsLockFile.exists()) {
        await studentsLockFile.copy('${backupDir.path}/${DatabaseHelper.studentsBoxName}.lock');
        debugPrint('DataImportService: Backed up students.lock');
      }
      
      if (await feesLockFile.exists()) {
        await feesLockFile.copy('${backupDir.path}/${DatabaseHelper.feesBoxName}.lock');
        debugPrint('DataImportService: Backed up fees.lock');
      }
      
      return backupDir.path;
    } catch (e) {
      debugPrint('DataImportService: Error creating backup - $e');
      throw Exception('Failed to create data backup: $e');
    }
  }
  
  /// Restore Hive data files from backup
  Future<void> _restoreHiveBackup(String backupPath) async {
    try {
      debugPrint('DataImportService: Restoring backup from $backupPath');
      
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        debugPrint('DataImportService: Backup directory does not exist');
        return;
      }
      
      // Close current Hive boxes before restoration
      try {
        if (Hive.isBoxOpen(DatabaseHelper.studentsBoxName)) {
          await Hive.box<Student>(DatabaseHelper.studentsBoxName).close();
        }
        if (Hive.isBoxOpen(DatabaseHelper.feesBoxName)) {
          await Hive.box<Fee>(DatabaseHelper.feesBoxName).close();
        }
      } catch (e) {
        debugPrint('DataImportService: Error closing boxes during restore - $e');
      }
      
      // Get Hive directory
      final tempBox = await Hive.openBox<Student>(DatabaseHelper.studentsBoxName);
      final hiveDir = Directory(tempBox.path!);
      final hiveParentDir = hiveDir.parent;
      await tempBox.close();
      
      // Restore files from backup
      final backupStudentsFile = File('$backupPath/${DatabaseHelper.studentsBoxName}.hive');
      final backupFeesFile = File('$backupPath/${DatabaseHelper.feesBoxName}.hive');
      final backupStudentsLockFile = File('$backupPath/${DatabaseHelper.studentsBoxName}.lock');
      final backupFeesLockFile = File('$backupPath/${DatabaseHelper.feesBoxName}.lock');
      
      if (await backupStudentsFile.exists()) {
        await backupStudentsFile.copy('${hiveParentDir.path}/${DatabaseHelper.studentsBoxName}.hive');
        debugPrint('DataImportService: Restored students.hive');
      }
      
      if (await backupFeesFile.exists()) {
        await backupFeesFile.copy('${hiveParentDir.path}/${DatabaseHelper.feesBoxName}.hive');
        debugPrint('DataImportService: Restored fees.hive');
      }
      
      if (await backupStudentsLockFile.exists()) {
        await backupStudentsLockFile.copy('${hiveParentDir.path}/${DatabaseHelper.studentsBoxName}.lock');
        debugPrint('DataImportService: Restored students.lock');
      }
      
      if (await backupFeesLockFile.exists()) {
        await backupFeesLockFile.copy('${hiveParentDir.path}/${DatabaseHelper.feesBoxName}.lock');
        debugPrint('DataImportService: Restored fees.lock');
      }
      
      // Reinitialize database
      await _databaseHelper.initDatabase();
      debugPrint('DataImportService: Database reinitialized after restore');
      
    } catch (e) {
      debugPrint('DataImportService: Error restoring backup - $e');
      throw Exception('Failed to restore data backup: $e');
    }
  }
  
  /// Clean up temporary backup directory
  Future<void> _cleanupBackup(String backupPath) async {
    try {
      final backupDir = Directory(backupPath);
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
        debugPrint('DataImportService: Cleaned up backup directory');
      }
    } catch (e) {
      debugPrint('DataImportService: Error cleaning up backup - $e');
      // Don't throw here, cleanup failure shouldn't break the main flow
    }
  }

  /// Step 4e: Reset counters with highest ID+1
  void _resetCounters(List<Student> students, List<Fee> fees) {
    int maxStudentId = 0;
    int maxFeeId = 0;

    for (final student in students) {
      if (student.id != null && student.id! > maxStudentId) {
        maxStudentId = student.id!;
      }
    }

    for (final fee in fees) {
      if (fee.id != null && fee.id! > maxFeeId) {
        maxFeeId = fee.id!;
      }
    }

    _databaseHelper.setCounters(
      studentMaxId: maxStudentId,
      feeMaxId: maxFeeId,
    );
  }

  /// Main import method that orchestrates all steps
  Future<ImportResult> importData(BuildContext context) async {
    String? backupPath;
    
    try {
      debugPrint('DataImportService: Starting import process');
      
      // Steps 1 & 2: Pick file and validate
      ExportData exportData;
      try {
        exportData = await _pickAndValidateJsonFile();
      } on Exception catch (e) {
        debugPrint('DataImportService: File selection/validation failed - $e');
        return ImportResult.error(
          message: e.toString().replaceFirst('Exception: ', ''),
          errors: [e.toString()],
        );
      } catch (e) {
        debugPrint('DataImportService: Unexpected error during file selection - $e');
        return ImportResult.error(
          message: 'File selection or validation failed',
          errors: [e.toString()],
        );
      }

      // Step 3: Show confirmation dialog
      final confirmed = await _showConfirmationDialog(context);
      if (!confirmed) {
        debugPrint('DataImportService: Import cancelled by user');
        return ImportResult.error(message: 'Import cancelled by user');
      }

      // Step 4a: Show progress dialog
      _showProgressDialog(context, 'Creating backup...');

      try {
        // Step 4a.1: Create backup of existing Hive data
        backupPath = await _createHiveBackup();
        debugPrint('DataImportService: Backup created at $backupPath');
      } catch (e) {
        debugPrint('DataImportService: Failed to create backup - $e');
        Navigator.of(context).pop(); // Close progress dialog
        return ImportResult.error(
          message: 'Failed to create backup before import',
          errors: [e.toString()],
        );
      }

      try {
        // Update progress
        Navigator.of(context).pop(); // Close backup progress
        _showProgressDialog(context, 'Importing data...');
        
        // Step 4b: Clear all data
        debugPrint('DataImportService: Clearing existing data');
        await _databaseHelper.clearAllData();

        // Step 4c: Convert JSON arrays to Student & Fee objects
        debugPrint('DataImportService: Converting JSON data to objects');
        List<Student> students;
        List<Fee> fees;
        
        try {
          students = _convertJsonToStudents(
            exportData.students.map((s) => s.toJson()).toList(),
          );
          fees = _convertJsonToFees(
            exportData.fees.map((f) => f.toJson()).toList(),
          );
          debugPrint('DataImportService: Converted ${students.length} students and ${fees.length} fees');
        } on FormatException catch (e) {
          debugPrint('DataImportService: FormatException during data conversion - $e');
          throw Exception('Backup file is corrupted or incompatible. Data conversion failed.');
        } catch (e) {
          debugPrint('DataImportService: Error during data conversion - $e');
          throw Exception('Failed to convert data from backup file: $e');
        }

        // Step 4d: Bulk insert
        debugPrint('DataImportService: Inserting bulk data');
        await _databaseHelper.insertBulkStudents(students);
        await _databaseHelper.insertBulkFees(fees);

        // Step 4e: Reset counters with highest ID+1
        debugPrint('DataImportService: Resetting ID counters');
        _resetCounters(students, fees);

        // Close progress dialog
        Navigator.of(context).pop();
        
        // Clean up backup on success
        if (backupPath != null) {
          await _cleanupBackup(backupPath);
        }

        debugPrint('DataImportService: Import completed successfully');
        // Step 5: Return ImportResult containing counts
        return ImportResult.success(
          message: 'Data imported successfully',
          importedStudents: students.length,
          importedFees: fees.length,
        );
        
      } catch (e) {
        debugPrint('DataImportService: Error during import process - $e');
        
        // Close progress dialog on error
        try {
          Navigator.of(context).pop();
        } catch (dialogError) {
          debugPrint('DataImportService: Error closing progress dialog - $dialogError');
        }
        
        // Show restore progress
        _showProgressDialog(context, 'Restoring backup...');
        
        // Attempt to restore backup if it exists
        if (backupPath != null) {
          try {
            debugPrint('DataImportService: Attempting to restore backup');
            await _restoreHiveBackup(backupPath);
            debugPrint('DataImportService: Backup restored successfully');
            
            Navigator.of(context).pop(); // Close restore progress
            
            // Clean up backup after successful restore
            await _cleanupBackup(backupPath);
            
            String errorMessage = 'Import failed but your original data has been restored.';
            if (e.toString().contains('corrupted or incompatible')) {
              errorMessage = e.toString().replaceFirst('Exception: ', '') + ' Your original data has been restored.';
            }
            
            return ImportResult.error(
              message: errorMessage,
              errors: [e.toString()],
            );
          } catch (restoreError) {
            debugPrint('DataImportService: Failed to restore backup - $restoreError');
            Navigator.of(context).pop(); // Close restore progress
            
            return ImportResult.error(
              message: 'Import failed and could not restore original data. Please restart the app.',
              errors: [e.toString(), 'Restore error: $restoreError'],
            );
          }
        } else {
          Navigator.of(context).pop(); // Close restore progress
          return ImportResult.error(
            message: 'Import failed and no backup was created',
            errors: [e.toString()],
          );
        }
      }
    } on Exception catch (e) {
      debugPrint('DataImportService: Exception in main import flow - $e');
      
      // Clean up backup if it exists
      if (backupPath != null) {
        await _cleanupBackup(backupPath);
      }
      
      return ImportResult.error(
        message: e.toString().replaceFirst('Exception: ', ''),
        errors: [e.toString()],
      );
    } catch (e) {
      debugPrint('DataImportService: Unexpected error in main import flow - $e');
      
      // Clean up backup if it exists
      if (backupPath != null) {
        await _cleanupBackup(backupPath);
      }
      
      return ImportResult.error(
        message: 'Import failed due to unexpected error',
        errors: [e.toString()],
      );
    }
  }

  /// Alternative method that takes file path directly (for testing or manual file selection)
  Future<ImportResult> importFromFile(String filePath, BuildContext context) async {
    try {
      // This method is similar but uses the provided file path
      // Implementation would be similar to the main importData method
      // but starting from Step 2 directly
      return ImportResult.error(message: 'Not implemented yet');
    } catch (e) {
      return ImportResult.error(
        message: 'Import failed',
        errors: [e.toString()],
      );
    }
  }
}
