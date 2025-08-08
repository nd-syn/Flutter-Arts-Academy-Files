# Comprehensive Error Handling for DataImportService

## Overview
The DataImportService now includes comprehensive error handling to ensure data integrity and provide user-friendly error messages.

## Error Handling Features Implemented

### 1. Permission Denial Handling
- **Detection**: Catches permission-related errors during file access
- **User Message**: "Permission denied. Please grant file access permission in your device settings and try again."
- **Logging**: Uses `debugPrint` to log permission errors

### 2. FormatException and Missing Keys Handling
- **FormatException**: Specifically catches `FormatException` during JSON parsing
- **Missing Keys**: Validates presence of required JSON fields (`meta`, `schema`, `students`, `fees`)
- **User Message**: "Backup file is corrupted or incompatible." with specific details
- **Validation**: Checks schema version compatibility and data structure integrity

### 3. Backup and Restore System
- **Backup Creation**: Creates temporary backup of existing Hive files before clearing data
- **Automatic Restore**: If import fails after clearing data, automatically restores previous Hive files
- **File Handling**: Backs up both `.hive` and `.lock` files for complete data preservation
- **Cleanup**: Removes temporary backup files after successful import or restore

### 4. Comprehensive Logging
- **Error Logging**: All errors are logged using `debugPrint` with descriptive messages
- **Process Tracking**: Logs each step of the import process for debugging
- **Error Context**: Includes relevant context information in error messages

## Error Scenarios Handled

### File Selection Errors
- No file selected by user
- File permission denied
- Could not read file data
- Invalid file format

### Data Validation Errors
- Invalid JSON format
- Missing required fields (meta, schema, students, fees)
- Unsupported schema version
- Corrupted data structure
- Invalid data types

### Import Process Errors
- Backup creation failure
- Data clearing errors
- Data conversion failures
- Database insertion errors
- Counter reset errors

### Recovery Mechanisms
- Automatic backup before data clearing
- Rollback to previous state on failure
- User notification of recovery status
- Graceful error handling without data loss

## User-Friendly Error Messages

### Permission Errors
```
"Permission denied. Please grant file access permission in your device settings and try again."
```

### File Corruption Errors
```
"Backup file is corrupted or incompatible. [Specific reason]"
```

### Recovery Messages
```
"Import failed but your original data has been restored."
"Import failed and could not restore original data. Please restart the app."
```

## Technical Implementation Details

### Backup System
- Creates timestamped backup directory in temporary storage
- Copies all relevant Hive database files
- Maintains file structure and permissions
- Automatically cleans up on success

### Error Propagation
- Catches specific exception types (`FormatException`, `Exception`)
- Preserves error context while providing user-friendly messages
- Logs technical details for debugging while showing simple messages to users

### Progress Feedback
- Shows progress dialogs for backup creation, data import, and restoration
- Updates progress messages based on current operation
- Handles dialog cleanup on errors

## Usage Example

```dart
final importService = DataImportService();
final result = await importService.importData(context);

if (result.success) {
  // Import succeeded
  print('Imported ${result.importedStudents} students and ${result.importedFees} fees');
} else {
  // Import failed with user-friendly error message
  print('Error: ${result.message}');
  // Technical details available in result.errors for debugging
}
```

## Benefits

1. **Data Safety**: Never lose existing data due to automatic backup/restore
2. **User Experience**: Clear, actionable error messages
3. **Debugging**: Comprehensive logging for troubleshooting
4. **Robustness**: Handles edge cases and unexpected errors gracefully
5. **Recovery**: Automatic rollback on failures preserves data integrity
