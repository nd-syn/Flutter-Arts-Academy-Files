import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arts_academy/services/data_import_export_service.dart';
import 'package:arts_academy/services/database_helper.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/models/fee_model.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../test_helpers/fake_path_provider_platform.dart';
import '../test_helpers/test_data_helper.dart';

void main() {
  group('Corrupted File Tests', () {
    late DataImportExportService importExportService;
    late DatabaseHelper databaseHelper;
    late Directory tempDir;

    setUpAll(() async {
      // Set up fake path provider
      PathProviderPlatform.instance = FakePathProviderPlatform();
      
      // Initialize Hive with temporary directory
      tempDir = await Directory.systemTemp.createTemp('corrupt_test_');
      Hive.init(tempDir.path);
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(StudentAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FeeAdapter());
      }
    });

    setUp(() async {
      // Create fresh instances for each test
      databaseHelper = DatabaseHelper.instance;
      await databaseHelper.initDatabase();
      
      importExportService = DataImportExportService(databaseHelper: databaseHelper);
      
      // Clear any existing data
      await databaseHelper.clearAllData();
    });

    tearDown(() async {
      // Clean up after each test
      await databaseHelper.clearAllData();
    });

    tearDownAll(() async {
      // Clean up temp directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('JSON Syntax Errors', () {
      test('should handle completely malformed JSON gracefully', () async {
        // Arrange
        final corruptFile = File('${tempDir.path}/malformed.json');
        await corruptFile.writeAsString('{ this is not valid json at all! }');
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        expect(result.success, isFalse);
        expect(result.message, contains('Invalid JSON format'));
        expect(result.errors, isNotEmpty);
        expect(result.importedStudents, equals(0));
        expect(result.importedFees, equals(0));
        
        // Verify database is still empty
        final students = await databaseHelper.getAllStudents();
        final fees = await databaseHelper.getFees();
        expect(students, isEmpty);
        expect(fees, isEmpty);
        
        // Clean up
        await corruptFile.delete();
      });

      test('should handle truncated JSON file', () async {
        // Arrange - Create a valid JSON that's been cut off
        final validData = {
          'students': [TestDataHelper.generateTestStudents(1)[0].toMap()],
          'fees': []
        };
        final validJson = jsonEncode(validData);
        final truncatedJson = validJson.substring(0, validJson.length ~/ 2); // Cut in half
        
        final corruptFile = File('${tempDir.path}/truncated.json');
        await corruptFile.writeAsString(truncatedJson);
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        expect(result.success, isFalse);
        expect(result.message, contains('Invalid JSON format'));
        
        // Clean up
        await corruptFile.delete();
      });

      test('should handle JSON with wrong encoding', () async {
        // Arrange - Create file with binary data that looks like text
        final corruptFile = File('${tempDir.path}/wrong_encoding.json');
        final binaryData = List.generate(100, (i) => i % 256);
        await corruptFile.writeAsBytes(binaryData);
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        expect(result.success, isFalse);
        expect(result.message, contains('Invalid JSON format'));
        
        // Clean up
        await corruptFile.delete();
      });
    });

    group('Structure Corruption', () {
      test('should handle missing required top-level keys', () async {
        // Arrange
        final corruptData = {
          'not_students': [],
          'not_fees': []
        };
        
        final corruptFile = File('${tempDir.path}/missing_keys.json');
        await corruptFile.writeAsString(jsonEncode(corruptData));
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        expect(result.success, isFalse);
        expect(result.message, contains('Invalid data format'));
        expect(result.errors, contains(predicate((String error) => 
            error.contains('Missing "students" data'))));
        expect(result.errors, contains(predicate((String error) => 
            error.contains('Missing "fees" data'))));
        
        // Clean up
        await corruptFile.delete();
      });

      test('should handle wrong data types for arrays', () async {
        // Arrange
        final corruptData = {
          'students': 'not an array',
          'fees': 12345
        };
        
        final corruptFile = File('${tempDir.path}/wrong_types.json');
        await corruptFile.writeAsString(jsonEncode(corruptData));
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        expect(result.success, isFalse);
        expect(result.message, contains('Invalid data format'));
        expect(result.errors, contains(predicate((String error) => 
            error.contains('Students data must be a list'))));
        expect(result.errors, contains(predicate((String error) => 
            error.contains('Fees data must be a list'))));
        
        // Clean up
        await corruptFile.delete();
      });

      test('should handle mixed valid and invalid array elements', () async {
        // Arrange
        final validStudent = TestDataHelper.generateTestStudents(1)[0].toMap();
        final corruptData = {
          'students': [
            validStudent,
            'not a student object',
            {'incomplete': 'student'},
            null
          ],
          'fees': [
            'not a fee object',
            null,
            {'incomplete': 'fee'}
          ]
        };
        
        final corruptFile = File('${tempDir.path}/mixed_elements.json');
        await corruptFile.writeAsString(jsonEncode(corruptData));
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        expect(result.success, isTrue); // Should partially succeed
        expect(result.importedStudents, equals(1)); // Only the valid student
        expect(result.importedFees, equals(0)); // No valid fees
        expect(result.errors, isNotEmpty);
        
        // Clean up
        await corruptFile.delete();
      });
    });

    group('Field Corruption', () {
      test('should handle students with missing required fields', () async {
        // Arrange
        final incompleteStudent = {
          'name': 'Test Student',
          // Missing many required fields like 'class', 'school', etc.
        };
        
        final corruptData = {
          'students': [incompleteStudent],
          'fees': []
        };
        
        final corruptFile = File('${tempDir.path}/missing_fields.json');
        await corruptFile.writeAsString(jsonEncode(corruptData));
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        expect(result.success, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.any((error) => error.contains('missing required field')), isTrue);
        
        // Clean up
        await corruptFile.delete();
      });

      test('should handle invalid date formats', () async {
        // Arrange
        final studentWithBadDates = TestDataHelper.generateTestStudents(1)[0].toMap();
        studentWithBadDates['admission_date'] = 'not a valid date';
        studentWithBadDates['dob'] = 'invalid birthday';
        
        final corruptData = {
          'students': [studentWithBadDates],
          'fees': []
        };
        
        final corruptFile = File('${tempDir.path}/bad_dates.json');
        await corruptFile.writeAsString(jsonEncode(corruptData));
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        expect(result.success, isFalse); // Should fail due to date parsing errors
        expect(result.errors, isNotEmpty);
        expect(result.importedStudents, equals(0));
        
        // Clean up
        await corruptFile.delete();
      });

      test('should handle invalid numeric fields', () async {
        // Arrange
        final studentWithBadNumbers = TestDataHelper.generateTestStudents(1)[0].toMap();
        studentWithBadNumbers['fees'] = 'not a number';
        studentWithBadNumbers['version'] = 'invalid version';
        
        final corruptData = {
          'students': [studentWithBadNumbers],
          'fees': []
        };
        
        final corruptFile = File('${tempDir.path}/bad_numbers.json');
        await corruptFile.writeAsString(jsonEncode(corruptData));
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        expect(result.success, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.importedStudents, equals(0));
        
        // Clean up
        await corruptFile.delete();
      });

      test('should handle extremely long field values', () async {
        // Arrange
        final hugeString = 'x' * 100000; // 100KB string
        final studentWithHugeFields = TestDataHelper.generateTestStudents(1)[0].toMap();
        studentWithHugeFields['name'] = hugeString;
        studentWithHugeFields['address'] = hugeString;
        
        final corruptData = {
          'students': [studentWithHugeFields],
          'fees': []
        };
        
        final corruptFile = File('${tempDir.path}/huge_fields.json');
        await corruptFile.writeAsString(jsonEncode(corruptData));
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        // The app should either succeed (handling large data) or fail gracefully
        expect(result.success, isA<bool>());
        if (!result.success) {
          expect(result.errors, isNotEmpty);
        }
        
        // Clean up
        await corruptFile.delete();
      });
    });

    group('File System Issues', () {
      test('should handle empty file', () async {
        // Arrange
        final emptyFile = File('${tempDir.path}/empty.json');
        await emptyFile.writeAsString('');
        
        // Act
        final result = await importExportService.importData(emptyFile.path);
        
        // Assert
        expect(result.success, isFalse);
        expect(result.message, contains('Invalid JSON format'));
        
        // Clean up
        await emptyFile.delete();
      });

      test('should handle non-existent file', () async {
        // Act
        final result = await importExportService.importData('/path/to/nonexistent/file.json');
        
        // Assert
        expect(result.success, isFalse);
        expect(result.message, contains('Import file not found'));
      });

      test('should handle directory instead of file', () async {
        // Arrange
        final directory = Directory('${tempDir.path}/fake_file.json');
        await directory.create();
        
        // Act
        final result = await importExportService.importData(directory.path);
        
        // Assert
        expect(result.success, isFalse);
        expect(result.message, contains('Failed to import data'));
        
        // Clean up
        await directory.delete();
      });

      test('should handle very large files', () async {
        // Arrange - Create a large but valid JSON file
        final largeStudents = TestDataHelper.generateTestStudents(1000);
        final largeFees = TestDataHelper.generateTestFees(largeStudents, 5000);
        
        final largeData = {
          'students': largeStudents.map((s) => s.toMap()).toList(),
          'fees': largeFees.map((f) => f.toMap()).toList()
        };
        
        final largeFile = File('${tempDir.path}/large_file.json');
        final stopwatch = Stopwatch()..start();
        await largeFile.writeAsString(jsonEncode(largeData));
        stopwatch.stop();
        
        print('Created large file (${await largeFile.length()} bytes) in ${stopwatch.elapsedMilliseconds}ms');
        
        // Act
        final importStopwatch = Stopwatch()..start();
        final result = await importExportService.importData(largeFile.path);
        importStopwatch.stop();
        
        print('Import completed in ${importStopwatch.elapsedMilliseconds}ms');
        
        // Assert
        expect(result.success, isTrue);
        expect(result.importedStudents, equals(1000));
        expect(result.importedFees, equals(5000));
        
        // Import should complete in reasonable time (adjust threshold as needed)
        expect(importStopwatch.elapsedMilliseconds, lessThan(30000)); // 30 seconds max
        
        // Clean up
        await largeFile.delete();
      });
    });

    group('Character Encoding Issues', () {
      test('should handle files with special Unicode characters', () async {
        // Arrange
        final studentWithUnicode = TestDataHelper.generateTestStudents(1)[0];
        studentWithUnicode.name = '测试学生 José María Müller'; // Mixed Unicode
        studentWithUnicode.address = '123 Ålesund Street, São Paulo 🏠';
        studentWithUnicode.guardianName = 'Родитель Guardian';
        
        final unicodeData = {
          'students': [studentWithUnicode.toMap()],
          'fees': []
        };
        
        final unicodeFile = File('${tempDir.path}/unicode.json');
        await unicodeFile.writeAsString(jsonEncode(unicodeData), encoding: utf8);
        
        // Act
        final result = await importExportService.importData(unicodeFile.path);
        
        // Assert
        expect(result.success, isTrue);
        expect(result.importedStudents, equals(1));
        
        // Verify Unicode characters were preserved
        final importedStudents = await databaseHelper.getAllStudents();
        expect(importedStudents.first.name, equals('测试学生 José María Müller'));
        expect(importedStudents.first.address, equals('123 Ålesund Street, São Paulo 🏠'));
        expect(importedStudents.first.guardianName, equals('Родитель Guardian'));
        
        // Clean up
        await unicodeFile.delete();
      });

      test('should handle files with null bytes', () async {
        // Arrange
        final corruptFile = File('${tempDir.path}/null_bytes.json');
        final dataWithNulls = '{"students": [], "fees": []}\x00\x00\x00';
        await corruptFile.writeAsString(dataWithNulls);
        
        // Act
        final result = await importExportService.importData(corruptFile.path);
        
        // Assert
        // Should either succeed (ignoring null bytes) or fail gracefully
        expect(result.success, isA<bool>());
        if (!result.success) {
          expect(result.errors, isNotEmpty);
        }
        
        // Clean up
        await corruptFile.delete();
      });
    });

    group('Security and Edge Cases', () {
      test('should handle deeply nested JSON structures', () async {
        // Arrange - Create deeply nested but invalid structure
        Map<String, dynamic> deepNested = {};
        Map<String, dynamic> current = deepNested;
        
        // Create 100 levels of nesting
        for (int i = 0; i < 100; i++) {
          current['level$i'] = <String, dynamic>{};
          current = current['level$i'] as Map<String, dynamic>;
        }
        current['students'] = [];
        current['fees'] = [];
        
        final nestedFile = File('${tempDir.path}/deeply_nested.json');
        await nestedFile.writeAsString(jsonEncode(deepNested));
        
        // Act
        final result = await importExportService.importData(nestedFile.path);
        
        // Assert
        expect(result.success, isFalse);
        expect(result.message, contains('Invalid data format'));
        
        // Clean up
        await nestedFile.delete();
      });

      test('should handle JSON with circular references in strings', () async {
        // Arrange - JSON with what looks like circular reference patterns
        final circularLike = {
          'students': [{
            'name': 'Student referencing {"self": "recursive"}',
            'class': '10',
            'school': 'Test School',
            'version': 1,
            'guardian_name': 'Guardian',
            'guardian_phone': '+1234567890',
            'subjects': 'Math',
            'fees': 100,
            'address': 'Address with {nested: "object"} string',
            'admission_date': DateTime.now().toIso8601String(),
            'dob': DateTime.now().subtract(const Duration(days: 5475)).toIso8601String(),
          }],
          'fees': []
        };
        
        final circularFile = File('${tempDir.path}/circular_like.json');
        await circularFile.writeAsString(jsonEncode(circularLike));
        
        // Act
        final result = await importExportService.importData(circularFile.path);
        
        // Assert
        // Should handle the strings without issue
        expect(result.success, isTrue);
        expect(result.importedStudents, equals(1));
        
        // Clean up
        await circularFile.delete();
      });

      test('should handle concurrent access to corrupted file', () async {
        // Arrange
        final corruptFile = File('${tempDir.path}/concurrent.json');
        await corruptFile.writeAsString('{"invalid": json}');
        
        // Act - Try to import the same corrupted file multiple times concurrently
        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(importExportService.importData(corruptFile.path));
        }
        
        final results = await Future.wait(futures);
        
        // Assert - All should fail consistently
        for (final result in results) {
          expect(result.success, isFalse);
          expect(result.message, contains('Invalid JSON format'));
        }
        
        // Database should still be empty
        final students = await databaseHelper.getAllStudents();
        final fees = await databaseHelper.getFees();
        expect(students, isEmpty);
        expect(fees, isEmpty);
        
        // Clean up
        await corruptFile.delete();
      });
    });
  });
}
