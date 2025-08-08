# JSON Schema & Model Helpers Implementation

## Overview

This implementation extends the **Student** and **Fee** models with JSON serialization capabilities and defines a comprehensive wrapper JSON format for data export/import.

## Features Implemented

### 1. Model Extensions

#### Student Model (`lib/models/student_model.dart`)
- ✅ `Map<String, dynamic> toJson()` - Converts Student object to JSON (reuses existing `toMap()`)
- ✅ `static Student fromJson(Map<String, dynamic> json)` - Creates Student from JSON (reuses existing `fromMap()`)
- ✅ Profile pictures are encoded as base64 strings in JSON

#### Fee Model (`lib/models/fee_model.dart`)
- ✅ `Map<String, dynamic> toJson()` - Converts Fee object to JSON (reuses existing `toMap()`)
- ✅ `static Fee fromJson(Map<String, dynamic> json)` - Creates Fee from JSON (reuses existing `fromMap()`)

### 2. JSON Wrapper Schema (`lib/models/export_data.dart`)

The new export format follows this structure:

```json
{
  "meta": {
    "exported_at": "2025-08-07T12:00:00Z",
    "app_version": "1.0.0", 
    "schema": 1
  },
  "students": [
    {
      "id": 1,
      "name": "John Doe",
      "class": "Grade 10",
      "school": "ABC High School", 
      "version": "2023-2024",
      "guardian_name": "Jane Doe",
      "guardian_phone": "+1234567890",
      "student_phone": "+1234567891",
      "subjects": "[\"Math\", \"Science\", \"English\"]",
      "fees": 500.0,
      "address": "123 Main Street, City, State",
      "admission_date": "2023-09-01T00:00:00Z",
      "dob": "2008-05-15T00:00:00Z",
      "profile_pic": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
    }
  ],
  "fees": [
    {
      "fee_id": 1,
      "student_id": 1,
      "amount": 500.0,
      "payment_date": "2023-09-01T00:00:00Z",
      "payment_month": 9,
      "payment_year": 2023,
      "payment_status": "paid"
    }
  ]
}
```

### 3. Key Classes

#### ExportMeta
- `exportedAt` - ISO8601 timestamp of export
- `appVersion` - Application version (default: "1.0.0") 
- `schema` - Schema version for future compatibility (default: 1)

#### ExportData 
- `meta` - Export metadata
- `students` - List of student objects
- `fees` - List of fee objects

#### Methods:
- `toJson()` - Convert to JSON Map
- `fromJson()` - Create from JSON Map  
- `toJsonString()` - Serialize to JSON string
- `fromJsonString()` - Deserialize from JSON string
- `create()` - Factory method with automatic timestamp

### 4. Updated Data Import/Export Service

The `DataImportExportService` has been updated to:
- ✅ Export data using the new wrapper format
- ✅ Support importing both old and new formats (backward compatibility)
- ✅ Properly handle base64 encoded profile pictures

## Usage Examples

### Creating Export Data
```dart
final exportData = ExportData.create(
  students: studentList,
  fees: feeList,
  appVersion: '1.0.0',
  schema: 1,
);

// Convert to JSON string
final jsonString = exportData.toJsonString();
```

### Importing Data
```dart
// From JSON string
final exportData = ExportData.fromJsonString(jsonString);

// From JSON Map
final exportData = ExportData.fromJson(jsonMap);
```

### Model Serialization
```dart
// Student
final studentJson = student.toJson();
final student = Student.fromJson(studentJson);

// Fee  
final feeJson = fee.toJson();
final fee = Fee.fromJson(feeJson);
```

## Profile Picture Handling

- Profile pictures (`Uint8List`) are automatically converted to base64 strings in JSON
- Base64 strings are automatically decoded back to `Uint8List` when importing
- This ensures compatibility across different platforms and storage formats

## Backward Compatibility

The import service automatically detects the format:
- **New format**: Contains `meta` key with wrapper structure
- **Old format**: Direct `students` and `fees` arrays (legacy support)

## Testing

Run the test function to verify implementation:
```dart
import 'lib/models/export_data_test.dart';

// In your test or main function
testExportDataImplementation();
```

## Files Created/Modified

### New Files:
- `lib/models/export_data.dart` - Wrapper classes for JSON export
- `lib/models/export_example.json` - Example of new JSON format
- `lib/models/export_data_test.dart` - Test implementation
- `JSON_SCHEMA_README.md` - This documentation

### Modified Files:
- `lib/models/student_model.dart` - Added `toJson()` and `fromJson()` methods
- `lib/models/fee_model.dart` - Added `toJson()` and `fromJson()` methods  
- `lib/services/data_import_export_service.dart` - Updated to use new format

## Schema Versioning

The `schema` field in metadata allows for future format changes while maintaining backward compatibility. Current version is `1`.

## Best Practices

1. Always use `ExportData.create()` for new exports to ensure consistent metadata
2. Profile pictures are automatically handled as base64 - no manual encoding needed
3. The import service gracefully handles both old and new formats
4. Use the provided test function to verify your implementation works correctly

## Summary

✅ **Task Completed Successfully**

All requirements have been implemented:
1. ✅ Extended Student and Fee models with `toJson()` and `fromJson()` methods
2. ✅ Created wrapper JSON format with metadata structure
3. ✅ Included base64 encoding for profile pictures  
4. ✅ Updated export/import service with backward compatibility
5. ✅ Provided comprehensive testing and documentation
