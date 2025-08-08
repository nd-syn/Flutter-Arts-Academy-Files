import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arts_academy/services/data_import_export_service.dart';
import 'package:arts_academy/services/database_helper.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/models/fee_model.dart';
import 'package:arts_academy/models/import_result.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../test_helpers/fake_path_provider_platform.dart';
import '../test_helpers/test_data_helper.dart';

void main() {
  group('DataImportExportService Tests', () {
    late DataImportExportService importExportService;
    late DatabaseHelper databaseHelper;
    late Directory tempDir;

    setUpAll(() async {
      // Set up fake path provider
      PathProviderPlatform.instance = FakePathProviderPlatform();
      
      // Initialize Hive with temporary directory
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
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

    group('Export Functionality', () {
      test('should export empty database successfully', () async {
        // Act
        final exportFile = await importExportService.exportData();
        
        // Assert
        expect(await exportFile.exists(), isTrue);
        
        final content = await exportFile.readAsString();
        final data = jsonDecode(content);
        
        expect(data, containsPair('meta', isA<Map>()));
        expect(data['students'], isEmpty);
        expect(data['fees'], isEmpty);
        
        // Clean up
        await exportFile.delete();
      });

      test('should export database with sample data successfully', () async {
        // Arrange
        final testStudents = TestDataHelper.generateTestStudents(5);
        final testFees = TestDataHelper.generateTestFees(testStudents, 15);
        
        // Add test data to database
        for (final student in testStudents) {
          await databaseHelper.insertStudent(student);
        }
        for (final fee in testFees) {
          await databaseHelper.insertFee(fee);
        }
        
        // Act
        final exportFile = await importExportService.exportData();
        
        // Assert
        expect(await exportFile.exists(), isTrue);
        
        final content = await exportFile.readAsString();
        final data = jsonDecode(content);
        
        expect(data, containsPair('meta', isA<Map>()));
        expect(data['students'], hasLength(5));
        expect(data['fees'], hasLength(15));
        
        // Verify export metadata
        expect(data['meta']['exportDate'], isNotNull);
        expect(data['meta']['appVersion'], equals('1.0.0'));
        expect(data['meta']['schema'], equals(1));
        
        // Clean up
        await exportFile.delete();
      });
    });

    group('Import Functionality', () {
      test('should import data from valid export file successfully', () async {
        // Arrange
        final originalStudents = TestDataHelper.generateTestStudents(3);
        final originalFees = TestDataHelper.generateTestFees(originalStudents, 9);
        
        // Add original data to database
        for (final student in originalStudents) {
          await databaseHelper.insertStudent(student);
        }
        for (final fee in originalFees) {
          await databaseHelper.insertFee(fee);
        }
        
        // Export the data
        final exportFile = await importExportService.exportData();
        
        // Clear database to simulate fresh install
        await databaseHelper.clearAllData();
        
        // Verify database is empty
        final emptyStudents = await databaseHelper.getAllStudents();
        final emptyFees = await databaseHelper.getFees();
        expect(emptyStudents, isEmpty);
        expect(emptyFees, isEmpty);
        
        // Act - Import the data back
        final importResult = await importExportService.importData(exportFile.path);
        
        // Assert
        expect(importResult.success, isTrue);
        expect(importResult.importedStudents, equals(3));
        expect(importResult.importedFees, equals(9));
        expect(importResult.errors, isEmpty);
        
        // Clean up
        await exportFile.delete();
      });

      test('should handle corrupted JSON file gracefully', () async {
        // Arrange
        final corruptedFile = File('${tempDir.path}/corrupted.json');
        await corruptedFile.writeAsString('{ invalid json content }');
        
        // Act
        final importResult = await importExportService.importData(corruptedFile.path);
        
        // Assert
        expect(importResult.success, isFalse);
        expect(importResult.message, contains('Invalid JSON format'));
        expect(importResult.errors, isNotEmpty);
        
        // Clean up
        await corruptedFile.delete();
      });

      test('should handle missing file gracefully', () async {
        // Act
        final importResult = await importExportService.importData('/non/existent/file.json');
        
        // Assert
        expect(importResult.success, isFalse);
        expect(importResult.message, contains('Import file not found'));
      });

      test('should handle partial import failures', () async {
        // Arrange
        final validData = {
          'students': [
            TestDataHelper.generateTestStudents(1)[0].toMap(),
            {'invalid': 'student'}, // Invalid student data
          ],
          'fees': [
            {'invalid': 'fee'}, // Invalid fee data
          ]
        };
        
        final partialFile = File('${tempDir.path}/partial.json');
        await partialFile.writeAsString(jsonEncode(validData));
        
        // Act
        final importResult = await importExportService.importData(partialFile.path);
        
        // Assert
        expect(importResult.success, isTrue); // Should succeed partially
        expect(importResult.importedStudents, equals(1));
        expect(importResult.importedFees, equals(0));
        expect(importResult.errors, isNotEmpty);
        
        // Clean up
        await partialFile.delete();
      });
    });

    group('Database State Equality Tests', () {
      test('export then import should result in identical database state', () async {
        // Arrange - Create comprehensive test data
        final originalStudents = TestDataHelper.generateTestStudents(10);
        final originalFees = TestDataHelper.generateTestFees(originalStudents, 30);
        
        // Add original data to database
        final insertedStudentIds = <int>[];
        for (final student in originalStudents) {
          final id = await databaseHelper.insertStudent(student);
          insertedStudentIds.add(id);
        }
        
        final insertedFeeIds = <int>[];
        for (final fee in originalFees) {
          final id = await databaseHelper.insertFee(fee);
          insertedFeeIds.add(id);
        }
        
        // Capture original database state
        final originalStudentsFromDB = await databaseHelper.getAllStudents();
        final originalFeesFromDB = await databaseHelper.getFees();
        
        // Sort for consistent comparison
        originalStudentsFromDB.sort((a, b) => a.id!.compareTo(b.id!));
        originalFeesFromDB.sort((a, b) => a.id!.compareTo(b.id!));
        
        // Act - Export data
        final exportFile = await importExportService.exportData();
        
        // Clear database
        await databaseHelper.clearAllData();
        
        // Import data back
        final importResult = await importExportService.importData(exportFile.path);
        
        // Assert import was successful
        expect(importResult.success, isTrue);
        expect(importResult.errors, isEmpty);
        
        // Capture restored database state
        final restoredStudents = await databaseHelper.getAllStudents();
        final restoredFees = await databaseHelper.getFees();
        
        // Sort for consistent comparison
        restoredStudents.sort((a, b) => a.id!.compareTo(b.id!));
        restoredFees.sort((a, b) => a.id!.compareTo(b.id!));
        
        // Assert database state equality
        expect(restoredStudents.length, equals(originalStudentsFromDB.length));
        expect(restoredFees.length, equals(originalFeesFromDB.length));
        
        // Compare each student in detail
        for (int i = 0; i < originalStudentsFromDB.length; i++) {
          final original = originalStudentsFromDB[i];
          final restored = restoredStudents[i];
          
          expect(restored.name, equals(original.name));
          expect(restored.studentClass, equals(original.studentClass));
          expect(restored.school, equals(original.school));
          expect(restored.guardianName, equals(original.guardianName));
          expect(restored.guardianPhone, equals(original.guardianPhone));
          expect(restored.studentPhone, equals(original.studentPhone));
          expect(restored.subjects, equals(original.subjects));
          expect(restored.fees, equals(original.fees));
          expect(restored.address, equals(original.address));
          expect(restored.admissionDate, equals(original.admissionDate));
          expect(restored.dob, equals(original.dob));
        }
        
        // Compare each fee in detail
        for (int i = 0; i < originalFeesFromDB.length; i++) {
          final original = originalFeesFromDB[i];
          final restored = restoredFees[i];
          
          expect(restored.studentId, equals(original.studentId));
          expect(restored.amount, equals(original.amount));
          expect(restored.paymentDate, equals(original.paymentDate));
          expect(restored.paymentMonth, equals(original.paymentMonth));
          expect(restored.paymentYear, equals(original.paymentYear));
          expect(restored.paymentStatus, equals(original.paymentStatus));
        }
        
        // Clean up
        await exportFile.delete();
      });

      test('multiple export-import cycles should maintain data integrity', () async {
        // Arrange
        final originalStudents = TestDataHelper.generateTestStudents(5);
        final originalFees = TestDataHelper.generateTestFees(originalStudents, 15);
        
        // Add original data
        for (final student in originalStudents) {
          await databaseHelper.insertStudent(student);
        }
        for (final fee in originalFees) {
          await databaseHelper.insertFee(fee);
        }
        
        // Perform multiple export-import cycles
        for (int cycle = 1; cycle <= 3; cycle++) {
          // Export
          final exportFile = await importExportService.exportData();
          
          // Clear database
          await databaseHelper.clearAllData();
          
          // Import
          final importResult = await importExportService.importData(exportFile.path);
          
          // Verify import success
          expect(importResult.success, isTrue, 
                 reason: 'Import should succeed in cycle $cycle');
          expect(importResult.importedStudents, equals(5), 
                 reason: 'Should import 5 students in cycle $cycle');
          expect(importResult.importedFees, equals(15), 
                 reason: 'Should import 15 fees in cycle $cycle');
          
          // Clean up export file
          await exportFile.delete();
        }
        
        // Final verification - data should still be intact
        final finalStudents = await databaseHelper.getAllStudents();
        final finalFees = await databaseHelper.getFees();
        
        expect(finalStudents.length, equals(5));
        expect(finalFees.length, equals(15));
      });
    });

    group('Edge Cases and Stress Tests', () {
      test('should handle large dataset export/import', () async {
        // Arrange - Create large dataset
        final largeStudents = TestDataHelper.generateTestStudents(100);
        final largeFees = TestDataHelper.generateTestFees(largeStudents, 500);
        
        // Add data to database
        for (final student in largeStudents) {
          await databaseHelper.insertStudent(student);
        }
        for (final fee in largeFees) {
          await databaseHelper.insertFee(fee);
        }
        
        // Act - Export
        final exportFile = await importExportService.exportData();
        
        // Clear and import
        await databaseHelper.clearAllData();
        final importResult = await importExportService.importData(exportFile.path);
        
        // Assert
        expect(importResult.success, isTrue);
        expect(importResult.importedStudents, equals(100));
        expect(importResult.importedFees, equals(500));
        
        // Verify data integrity
        final restoredStudents = await databaseHelper.getAllStudents();
        final restoredFees = await databaseHelper.getFees();
        
        expect(restoredStudents.length, equals(100));
        expect(restoredFees.length, equals(500));
        
        // Clean up
        await exportFile.delete();
      });

      test('should handle empty strings and null values correctly', () async {
        // Arrange - Create student with edge case data
        final edgeCaseStudent = Student(
          name: '',
          studentClass: '10',
          school: '',
          version: 1,
          guardianName: '',
          guardianPhone: '',
          studentPhone: '',
          subjects: '',
          fees: 0,
          address: '',
          admissionDate: DateTime.now(),
          dob: DateTime.now().subtract(const Duration(days: 6000)),
        );
        
        await databaseHelper.insertStudent(edgeCaseStudent);
        
        // Act
        final exportFile = await importExportService.exportData();
        await databaseHelper.clearAllData();
        final importResult = await importExportService.importData(exportFile.path);
        
        // Assert
        expect(importResult.success, isTrue);
        
        final restoredStudents = await databaseHelper.getAllStudents();
        expect(restoredStudents.length, equals(1));
        
        final restored = restoredStudents.first;
        expect(restored.name, equals(''));
        expect(restored.school, equals(''));
        expect(restored.guardianName, equals(''));
        
        // Clean up
        await exportFile.delete();
      });
    });
  });
}
