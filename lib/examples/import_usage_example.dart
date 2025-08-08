import 'package:flutter/material.dart';
import '../services/data_import_service.dart';
import '../models/import_result.dart';

/// Example implementation showing how to use the DataImportService
class ImportUsageExample extends StatefulWidget {
  const ImportUsageExample({Key? key}) : super(key: key);

  @override
  State<ImportUsageExample> createState() => _ImportUsageExampleState();
}

class _ImportUsageExampleState extends State<ImportUsageExample> {
  final DataImportService _importService = DataImportService();
  
  /// Method to handle import button press
  Future<void> _handleImport() async {
    try {
      // Call the import service
      final ImportResult result = await _importService.importData(context);
      
      // Handle the result
      if (result.success) {
        // Show success message
        _showResultDialog(
          title: 'Import Successful',
          message: result.message,
          details: 'Students imported: ${result.importedStudents}\n'
                  'Fees imported: ${result.importedFees}',
          isSuccess: true,
        );
      } else {
        // Show error message
        _showResultDialog(
          title: 'Import Failed',
          message: result.message,
          details: result.errors.join('\n'),
          isSuccess: false,
        );
      }
    } catch (e) {
      // Handle unexpected errors
      _showResultDialog(
        title: 'Import Error',
        message: 'An unexpected error occurred',
        details: e.toString(),
        isSuccess: false,
      );
    }
  }

  /// Show result dialog after import
  void _showResultDialog({
    required String title,
    required String message,
    required String details,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              color: isSuccess ? Colors.green : Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Details:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  details,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Import Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import Data from JSON File',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Allow you to select a JSON file'),
            const Text('• Validate the file format and schema'),
            const Text('• Ask for confirmation to erase current data'),
            const Text('• Show progress during import'),
            const Text('• Import students and fees from the file'),
            const Text('• Update database counters'),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requirements:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• File must be in JSON format (.json)'),
                    Text('• File must have meta.schema = 1'),
                    Text('• File must contain "students" and "fees" arrays'),
                    Text('• Profile pictures stored as base64 strings'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleImport,
                icon: const Icon(Icons.file_upload),
                label: const Text('Import Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display import statistics
class ImportStatsWidget extends StatelessWidget {
  final ImportResult result;
  
  const ImportStatsWidget({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Results',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  result.success ? 'Success' : 'Failed',
                  style: TextStyle(
                    color: result.success ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Message: ${result.message}'),
            if (result.importedStudents != null) ...[
              const SizedBox(height: 4),
              Text('Students imported: ${result.importedStudents}'),
            ],
            if (result.importedFees != null) ...[
              const SizedBox(height: 4),
              Text('Fees imported: ${result.importedFees}'),
            ],
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Errors:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              ...result.errors.map((error) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Text(
                  '• $error',
                  style: const TextStyle(color: Colors.red),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
