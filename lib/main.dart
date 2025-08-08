import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arts_academy/screens/home_screen.dart';
import 'package:arts_academy/utils/constants.dart';
import 'package:arts_academy/utils/theme.dart';
import 'package:arts_academy/services/database_helper.dart';
import 'package:arts_academy/services/school_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive database
  await DatabaseHelper.instance.initDatabase();
  
  // Initialize School service
  await SchoolService.instance.initSchoolService();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      home: const HomeScreen(),
    );
  }
}

