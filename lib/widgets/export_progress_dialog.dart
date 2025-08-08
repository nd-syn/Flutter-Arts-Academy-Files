import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:arts_academy/services/enhanced_export_service.dart';

class ExportProgressDialog extends StatefulWidget {
  final EnhancedExportService exportService;
  
  const ExportProgressDialog({
    Key? key,
    required this.exportService,
  }) : super(key: key);

  @override
  State<ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<ExportProgressDialog> {
  double _progress = 0.0;
  String _status = 'Preparing export...';
  StreamSubscription<double>? _progressSubscription;
  bool _isExporting = false;
  File? _exportedFile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _error = null;
    });

    // Listen to progress updates
    _progressSubscription = widget.exportService.progressStream.listen(
      (progress) {
        setState(() {
          _progress = progress;
          _status = _getStatusMessage(progress);
        });
      },
    );

    try {
      // Start the export process
      final file = await widget.exportService.exportData();
      
      setState(() {
        _exportedFile = file;
        _isExporting = false;
        _status = 'Export completed successfully!';
      });
      
      // Show success message
      _showSuccessSnackBar(file);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isExporting = false;
        _status = 'Export failed';
      });
      
      // Show error message
      _showErrorSnackBar(e.toString());
    }
  }

  String _getStatusMessage(double progress) {
    if (progress <= 0.1) return 'Requesting permissions...';
    if (progress <= 0.2) return 'Fetching student data...';
    if (progress <= 0.3) return 'Fetching fee data...';
    if (progress <= 0.5) return 'Building JSON data...';
    if (progress <= 0.6) return 'Determining save location...';
    if (progress <= 0.7) return 'Creating export file...';
    if (progress <= 0.9) return 'Writing data to file...';
    if (progress >= 1.0) return 'Export completed!';
    return 'Processing...';
  }

  void _showSuccessSnackBar(File file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data exported successfully to: ${file.path}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _startExport();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exporting Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _error != null ? Colors.red : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress percentage
          Text(
            '${(_progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          
          // Status message
          Text(
            _status,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          
          // Error message (if any)
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          
          // Success info (if completed)
          if (_exportedFile != null && _error == null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'File saved to:',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _exportedFile!.path,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_isExporting)
          TextButton(
            onPressed: null,
            child: const Text('Exporting...'),
          )
        else if (_error != null)
          TextButton(
            onPressed: _startExport,
            child: const Text('Retry'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(context).pop(_exportedFile),
            child: const Text('Close'),
          ),
      ],
    );
  }
}

/// Helper function to show the export dialog
Future<File?> showExportDialog(
  BuildContext context, {
  EnhancedExportService? exportService,
}) async {
  final service = exportService ?? EnhancedExportService();
  
  try {
    final result = await showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExportProgressDialog(exportService: service),
    );
    
    return result;
  } finally {
    // Clean up the service if we created it
    if (exportService == null) {
      service.dispose();
    }
  }
}
