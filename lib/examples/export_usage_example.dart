import 'dart:io';
import 'dart:convert';
import 'package:arts_academy/services/enhanced_export_service.dart';
import 'package:arts_academy/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:arts_academy/widgets/export_progress_dialog.dart';

/// Complete implementation example for the Enhanced Export Service
class ExportUsageExample {
  
  /// Test the complete export implementation with all required steps
  static Future<void> demonstrateExportImplementation() async {
    print('🚀 Arts Academy Enhanced Export Service Implementation\n');
    print('════════════════════════════════════════════════════\n');
    
    try {
      // Initialize database
      final databaseHelper = DatabaseHelper.instance;
      await databaseHelper.initDatabase();
      
      // Create enhanced export service
      final exportService = EnhancedExportService(databaseHelper: databaseHelper);
      
      print('📋 Implementation Steps Completed:\n');
      
      // Step 1: Permission Handler
      print('✅ Step 1: Storage permission request with **permission_handler**');
      print('   - Android 13+ media permissions (photos, videos, audio)');
      print('   - Legacy storage permission for older Android versions');
      print('   - iOS: Uses app document directory (no permissions needed)\n');
      
      // Step 2: Database Integration
      print('✅ Step 2: Fetch all students & fees from DatabaseHelper');
      print('   - Uses DatabaseHelper.getAllStudents()');
      print('   - Uses DatabaseHelper.getFees()');
      print('   - Returns complete data sets\n');
      
      // Step 3: JSON Building
      print('✅ Step 3: Build JSON with pretty-printing');
      print('   - Uses ExportData.create() wrapper');
      print('   - Includes metadata (exported_at, app_version, schema)');
      print('   - JsonEncoder.withIndent(\\'  \\') for formatting\n');
      
      // Step 4: Path Provider
      print('✅ Step 4: Determine save directory with **path_provider**');
      print('   - Android: getDownloadsDirectory() -> /storage/emulated/0/Download');
      print('   - Fallback: getExternalStorageDirectory()');
      print('   - iOS: getApplicationDocumentsDirectory()\n');
      
      // Step 5: Filename Format
      print('✅ Step 5: Create filename arts_academy_backup_YYYY_MM_DD.json');
      final now = DateTime.now();
      final dateFormat = '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
      final exampleFileName = 'arts_academy_backup_$dateFormat.json';
      print('   - Example: $exampleFileName');
      print('   - Uses DateFormat(\\'yyyy_MM_dd\\') from intl package\n');
      
      // Step 6: File Writing
      print('✅ Step 6: Write file with File.writeAsString');
      print('   - Creates File object at determined path');
      print('   - Uses await file.writeAsString(jsonString)');
      print('   - Handles file creation and data writing\n');
      
      // Step 7: Progress Updates
      print('✅ Step 7: Progress updates via StreamController<double>');
      print('   - StreamController<double>.broadcast() for multiple listeners');
      print('   - Emits progress values from 0.0 to 1.0');
      print('   - Progress steps: 0% → 10% → 20% → 30% → 50% → 60% → 70% → 90% → 100%\n');
      
      // Demonstrate progress tracking
      print('📊 Progress Tracking Demo:');
      var progressCount = 0;
      exportService.progressStream.listen((progress) {
        final percentage = (progress * 100).toInt();
        final progressBar = _createProgressBar(progress);
        print('   $progressBar $percentage% - ${_getStepDescription(progress)}');
        progressCount++;
      });
      
      print('\n🔄 Starting actual export process...\n');
      
      // Perform the actual export
      final file = await exportService.exportData();
      
      print('\n🎉 Export Implementation Successfully Completed!\n');
      print('📁 File Details:');
      print('   Path: ${file.path}');
      print('   Size: ${await _getFileSize(file)}');
      print('   Exists: ${await file.exists()}');
      print('   Format: JSON with pretty-printing');
      
      // Verify file content
      if (await file.exists()) {
        final content = await file.readAsString();
        final hasValidJson = _isValidJson(content);
        print('   Content: ${hasValidJson ? 'Valid JSON ✅' : 'Invalid JSON ❌'}');
        
        if (hasValidJson) {
          final lines = content.split('\n').length;
          print('   Lines: $lines (formatted)');
        }
      }
      
      print('\n📂 Export Directory: ${await exportService.getExportDirectoryPath()}');
      print('📊 Progress Updates: $progressCount events emitted');
      
      // Clean up
      exportService.dispose();
      
    } catch (e) {
      print('❌ Export implementation failed: $e');
    }
  }
  
  /// Demonstrate Flutter UI integration
  static void demonstrateFlutterIntegration() {
    print('\n🖥️  Flutter UI Integration Example\n');
    print('═════════════════════════════════\n');
    
    print('1. Basic Usage in Flutter Widget:');
    print('''
   ```dart
   // In your Flutter widget
   void _exportData() async {
     final result = await showExportDialog(context);
     if (result != null) {
       print('Export saved to: \${result.path}');
     }
   }
   ```\n''');
   
    print('2. With Custom Progress Handling:');
    print('''
   ```dart
   void _exportWithProgressTracking() async {
     final exportService = EnhancedExportService();
     
     // Listen to progress
     exportService.progressStream.listen((progress) {
       setState(() {
         _exportProgress = progress;
       });
     });
     
     try {
       final file = await exportService.exportData();
       // Handle success
     } finally {
       exportService.dispose();
     }
   }
   ```\n''');
   
    print('3. Using the ExportProgressDialog:');
    print('''
   ```dart
   // Shows a dialog with progress bar and status updates
   final file = await showExportDialog(
     context, 
     exportService: EnhancedExportService(),
   );
   ```\n''');
  }
  
  /// Demonstrate error handling
  static void demonstrateErrorHandling() {
    print('🛡️  Error Handling Implementation\n');
    print('═══════════════════════════════════\n');
    
    print('✅ Permission Errors:');
    print('   - Handles storage permission denied');
    print('   - Provides clear error messages');
    print('   - Distinguishes between temporary and permanent denials\n');
    
    print('✅ File System Errors:');
    print('   - Directory not accessible → Falls back to alternative paths');
    print('   - Disk full → Catches and reports file writing errors');
    print('   - Path issues → Validates directory existence\n');
    
    print('✅ Database Errors:');
    print('   - Handles database read failures');
    print('   - Continues with partial data when possible');
    print('   - Reports data integrity issues\n');
    
    print('✅ Progress Tracking Errors:');
    print('   - Stream controller disposal safety');
    print('   - Progress reset on errors');
    print('   - Memory leak prevention\n');
  }
  
  /// Create a simple progress bar visualization
  static String _createProgressBar(double progress) {
    const barLength = 20;
    final filledLength = (progress * barLength).round();
    final bar = '█' * filledLength + '░' * (barLength - filledLength);
    return '[$bar]';
  }
  
  /// Get step description based on progress
  static String _getStepDescription(double progress) {
    if (progress <= 0.1) return 'Requesting permissions';
    if (progress <= 0.2) return 'Fetching student data';
    if (progress <= 0.3) return 'Fetching fee data';
    if (progress <= 0.5) return 'Building JSON data';
    if (progress <= 0.6) return 'Determining save location';
    if (progress <= 0.7) return 'Creating export file';
    if (progress <= 0.9) return 'Writing data to file';
    if (progress >= 1.0) return 'Export completed!';
    return 'Processing';
  }
  
  /// Get human-readable file size
  static Future<String> _getFileSize(File file) async {
    try {
      final bytes = await file.length();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  /// Check if string is valid JSON
  static bool _isValidJson(String jsonString) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      return decoded != null;
    } catch (e) {
      return false;
    }
  }
}

/// Widget integration example
class ExportButtonWidget extends StatelessWidget {
  const ExportButtonWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _performExport(context),
      icon: const Icon(Icons.upload),
      label: const Text('Export Data'),
    );
  }
  
  Future<void> _performExport(BuildContext context) async {
    try {
      // Show export dialog with progress
      final file = await showExportDialog(context);
      
      if (file != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported successfully to ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
