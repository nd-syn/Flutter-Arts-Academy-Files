import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/models/fee_model.dart';
import 'package:arts_academy/models/export_data.dart';
import 'package:arts_academy/services/database_helper.dart';

class EnhancedExportService {
  final DatabaseHelper _databaseHelper;
  final StreamController<double> _progressController = StreamController<double>.broadcast();

  EnhancedExportService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Stream for progress updates (0.0 to 1.0)
  Stream<double> get progressStream => _progressController.stream;

  /// Exports all data (students and fees) to a JSON file with progress updates
  /// Returns the created file
  Future<File> exportData() async {
    try {
      // Step 1: Request storage permissions (10% progress)
      _emitProgress(0.0);
      await _requestStoragePermissions();
      _emitProgress(0.1);

      // Step 2: Fetch all students & fees from DatabaseHelper (30% progress)
      final students = await _databaseHelper.getAllStudents();
      _emitProgress(0.2);
      
      final fees = await _databaseHelper.getFees();
      _emitProgress(0.3);

      // Step 3: Build JSON, pretty-print (50% progress)
      final exportData = ExportData.create(
        students: students,
        fees: fees,
        appVersion: '1.0.0',
        schema: 1,
      );
      _emitProgress(0.4);

      // Convert to pretty-printed JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData.toJson());
      _emitProgress(0.5);

      // Step 4: Determine save directory with path_provider (70% progress)
      final saveDirectory = await _getSaveDirectory();
      _emitProgress(0.6);

      // Step 5: Create filename arts_academy_backup_YYYY_MM_DD.json (80% progress)
      final file = await _createExportFile(saveDirectory);
      _emitProgress(0.7);

      // Step 6: Write file with File.writeAsString (90% progress)
      await file.writeAsString(jsonString);
      _emitProgress(0.9);

      // Step 7: Return file reference (100% progress)
      _emitProgress(1.0);
      
      return file;
    } catch (e) {
      _emitProgress(0.0); // Reset progress on error
      throw Exception('Failed to export data: $e');
    }
  }

  /// Step 1: Request storage permissions with permission_handler
  Future<void> _requestStoragePermissions() async {
    if (Platform.isAndroid) {
      // Check Android version to determine which permissions to request
      final androidInfo = await _getAndroidVersion();
      
      if (androidInfo >= 33) {
        // For Android 13+ (API 33+), request specific media permissions
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];
        
        for (final permission in permissions) {
          final status = await permission.status;
          if (status.isDenied || status.isPermanentlyDenied) {
            final result = await permission.request();
            if (!result.isGranted) {
              throw Exception('Storage permission is required for data export');
            }
          }
        }
      } else {
        // For older Android versions, request storage permission
        final permission = Permission.storage;
        final status = await permission.status;
        
        if (status.isDenied || status.isPermanentlyDenied) {
          final result = await permission.request();
          if (!result.isGranted) {
            throw Exception('Storage permission is required for data export');
          }
        }
      }
    }
    // iOS doesn't require explicit permissions for app's document directory
  }

  /// Step 4: Determine save directory with path_provider (getDownloadsDirectory() on Android)
  Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      // Try to get Downloads directory on Android
      try {
        final downloadsDirectory = Directory('/storage/emulated/0/Download');
        if (await downloadsDirectory.exists()) {
          return downloadsDirectory;
        }
      } catch (e) {
        // If Downloads directory is not accessible, fall back to other options
      }
      
      // Fallback to external storage directory
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir;
      }
      
      // Final fallback to application documents directory
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      // For iOS, use documents directory
      return await getApplicationDocumentsDirectory();
    } else {
      // For other platforms, use documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Step 5: Create filename arts_academy_backup_YYYY_MM_DD.json
  Future<File> _createExportFile(Directory directory) async {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy_MM_dd');
    final dateString = formatter.format(now);
    
    // Create filename with the exact format requested
    final fileName = 'arts_academy_backup_$dateString.json';
    
    return File('${directory.path}/$fileName');
  }

  /// Get Android SDK version (simplified implementation)
  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      // This is a simplified version. In a real app, you might use
      // device_info_plus package to get actual Android version
      return 33; // Assume Android 13+ for now
    }
    return 0;
  }

  /// Emit progress update via StreamController<double>
  void _emitProgress(double progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress.clamp(0.0, 1.0));
    }
  }

  /// Get the export directory path for display purposes
  Future<String> getExportDirectoryPath() async {
    final directory = await _getSaveDirectory();
    return directory.path;
  }

  /// Dispose method to close the stream controller
  void dispose() {
    _progressController.close();
  }
}
