import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/student.dart';
import 'theme/luxury_theme.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';

final themeModeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(StudentAdapter());
  await Hive.openBox<Student>('students');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => MaterialApp(
        title: 'ArtsAcademy',
        theme: LuxuryTheme.theme,
        darkTheme: LuxuryTheme.darkTheme,
        themeMode: mode,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/dashboard': (_) => const DashboardScreen(),
        },
      ),
    );
  }
}
