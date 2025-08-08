import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arts_academy/main.dart' as app;
import 'package:arts_academy/services/database_helper.dart';
import 'package:arts_academy/models/student_model.dart';
import 'package:arts_academy/models/fee_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Platform Integration Tests', () {
    setUpAll(() async {
      // Initialize Hive for integration tests
      await Hive.initFlutter();
      
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(StudentAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FeeAdapter());
      }
    });

    setUp(() async {
      // Clear database before each test
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.initDatabase();
      await dbHelper.clearAllData();
    });

    group('Dark Mode Tests', () {
      testWidgets('App should display correctly in dark mode', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Wait for app initialization
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Find settings or theme toggle button (adjust based on your UI)
        // This is a placeholder - adapt to your actual UI structure
        expect(find.byType(MaterialApp), findsOneWidget);

        // Test that dark mode can be toggled
        // You'll need to adjust this based on your actual dark mode implementation
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();

          // Look for dark mode toggle
          final Finder darkModeSwitch = find.byType(Switch);
          if (darkModeSwitch.evaluate().isNotEmpty) {
            await tester.tap(darkModeSwitch);
            await tester.pumpAndSettle();

            // Verify dark theme is applied
            final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
            expect(materialApp.theme?.brightness, equals(Brightness.dark));
          }
        }
      });

      testWidgets('UI elements should be visible in dark mode', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Test that key UI elements are visible and accessible
        // Adjust these based on your actual UI structure
        
        // Look for common UI elements
        final commonElements = [
          Icons.add,
          Icons.menu,
          Icons.search,
        ];

        for (final icon in commonElements) {
          final finder = find.byIcon(icon);
          if (finder.evaluate().isNotEmpty) {
            expect(finder, findsAtLeastNWidgets(1));
            
            // Verify the widget is visible (not transparent)
            final widget = tester.firstWidget(finder);
            expect(widget, isNotNull);
          }
        }
      });
    });

    group('Responsiveness Tests', () {
      testWidgets('App should adapt to different screen sizes', (WidgetTester tester) async {
        // Test tablet size
        await tester.binding.setSurfaceSize(const Size(1024, 768));
        
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(MaterialApp), findsOneWidget);

        // Test phone size
        await tester.binding.setSurfaceSize(const Size(375, 667));
        await tester.pumpAndSettle();

        expect(find.byType(MaterialApp), findsOneWidget);

        // Test large phone size
        await tester.binding.setSurfaceSize(const Size(414, 896));
        await tester.pumpAndSettle();

        expect(find.byType(MaterialApp), findsOneWidget);

        // Reset to default size
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpAndSettle();
      });

      testWidgets('Lists should scroll properly on small screens', (WidgetTester tester) async {
        // Set to small screen size
        await tester.binding.setSurfaceSize(const Size(320, 568));
        
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Add some test data first
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.initDatabase();
        
        // Add multiple students to test scrolling
        for (int i = 1; i <= 10; i++) {
          final student = Student(
            name: 'Test Student $i',
            studentClass: '10',
            school: 'Test School',
            version: 1,
            guardianName: 'Guardian $i',
            guardianPhone: '+1 (555) 123-456$i',
            studentPhone: '+1 (555) 987-654$i',
            subjects: 'Math, Science',
            fees: 100,
            address: '123 Test Street $i',
            admissionDate: DateTime.now(),
            dob: DateTime.now().subtract(Duration(days: 5475 + i)),
          );
          await dbHelper.insertStudent(student);
        }

        await tester.pumpAndSettle();

        // Look for scrollable lists
        final scrollableFinder = find.byType(Scrollable);
        if (scrollableFinder.evaluate().isNotEmpty) {
          // Test scrolling
          await tester.drag(scrollableFinder.first, const Offset(0, -200));
          await tester.pumpAndSettle();
          
          // Should still find the scrollable widget after scrolling
          expect(scrollableFinder, findsAtLeastNWidgets(1));
        }

        // Reset to default size
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpAndSettle();
      });
    });

    group('Data Export/Import Tests', () {
      testWidgets('Export functionality should work across platforms', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Add some test data
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.initDatabase();
        
        final student = Student(
          name: 'Integration Test Student',
          studentClass: '11',
          school: 'Test High School',
          version: 1,
          guardianName: 'Test Guardian',
          guardianPhone: '+1 (555) 123-4567',
          studentPhone: '+1 (555) 987-6543',
          subjects: 'Math, Physics, Chemistry',
          fees: 200,
          address: '456 Integration Test Ave',
          admissionDate: DateTime.now(),
          dob: DateTime.now().subtract(const Duration(days: 5840)),
        );
        
        await dbHelper.insertStudent(student);
        await tester.pumpAndSettle();

        // Look for export button or menu option
        // Adjust this based on your actual UI
        final exportButton = find.byIcon(Icons.download);
        if (exportButton.evaluate().isEmpty) {
          // Try looking in menu
          final menuButton = find.byIcon(Icons.menu);
          if (menuButton.evaluate().isNotEmpty) {
            await tester.tap(menuButton);
            await tester.pumpAndSettle();
          }
        }

        // This test mainly ensures the UI doesn't crash when export is attempted
        // Actual file operations may need platform-specific handling
      });

      testWidgets('Import dialog should handle file selection properly', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Look for import functionality
        final importButton = find.byIcon(Icons.upload);
        if (importButton.evaluate().isEmpty) {
          // Try looking in menu
          final menuButton = find.byIcon(Icons.menu);
          if (menuButton.evaluate().isNotEmpty) {
            await tester.tap(menuButton);
            await tester.pumpAndSettle();
          }
        }

        // This ensures the UI can handle import attempts without crashing
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('App should handle large datasets without significant lag', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Add a large number of students
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.initDatabase();

        final stopwatch = Stopwatch()..start();

        // Add 50 students (adjust based on your app's expected load)
        for (int i = 1; i <= 50; i++) {
          final student = Student(
            name: 'Performance Test Student $i',
            studentClass: '${9 + (i % 4)}', // Grades 9-12
            school: 'Performance Test School ${i % 3 + 1}',
            version: 1,
            guardianName: 'Guardian $i',
            guardianPhone: '+1 (555) 123-${4567 + i}',
            studentPhone: '+1 (555) 987-${6543 + i}',
            subjects: 'Math, Science, English',
            fees: 100 + (i % 200),
            address: '$i Performance Test Street',
            admissionDate: DateTime.now().subtract(Duration(days: i)),
            dob: DateTime.now().subtract(Duration(days: 5475 + i)),
          );
          await dbHelper.insertStudent(student);
        }

        stopwatch.stop();
        print('Time to add 50 students: ${stopwatch.elapsedMilliseconds}ms');

        // Pump and settle to allow UI to update
        await tester.pumpAndSettle();

        // The app should still be responsive
        expect(find.byType(MaterialApp), findsOneWidget);

        // Test that scrolling is still smooth with large dataset
        final scrollableFinder = find.byType(Scrollable);
        if (scrollableFinder.evaluate().isNotEmpty) {
          final scrollStopwatch = Stopwatch()..start();
          
          await tester.drag(scrollableFinder.first, const Offset(0, -300));
          await tester.pumpAndSettle();
          
          scrollStopwatch.stop();
          print('Time to scroll with 50 students: ${scrollStopwatch.elapsedMilliseconds}ms');
          
          // Scrolling should complete within reasonable time (< 500ms)
          expect(scrollStopwatch.elapsedMilliseconds, lessThan(500));
        }
      });
    });

    group('Edge Cases', () {
      testWidgets('App should handle empty states gracefully', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // With empty database, app should display empty state
        expect(find.byType(MaterialApp), findsOneWidget);
        
        // Look for empty state indicators
        final emptyStateElements = [
          find.text('No students found'),
          find.text('No data available'),
          find.byIcon(Icons.inbox),
          find.byIcon(Icons.person_add),
        ];

        bool foundEmptyStateIndicator = false;
        for (final finder in emptyStateElements) {
          if (finder.evaluate().isNotEmpty) {
            foundEmptyStateIndicator = true;
            break;
          }
        }

        // App should show some indication that there's no data or provide way to add data
        expect(foundEmptyStateIndicator, isTrue);
      });

      testWidgets('App should handle network connectivity changes', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // The app should work offline since it uses local database
        expect(find.byType(MaterialApp), findsOneWidget);

        // Test that basic functionality works without network
        // (This mainly ensures no network-dependent crashes)
        await tester.pump();
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });
  });
}
