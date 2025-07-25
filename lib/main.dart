import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'config/app_theme.dart';
import 'screens/pdf_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize pdfrx with platform-specific method
  try {
    if (kIsWeb) {
      // Use Flutter-specific initialization for web
      pdfrxFlutterInitialize();
    } else {
      // Use standard initialization for mobile/desktop
      await pdfrxInitialize();
    }
  } catch (e) {
    // Initialization might fail on some platforms, continue anyway
    if (kDebugMode) {
      debugPrint('pdfrx initialization: $e');
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Paper PDF Viewer',
      theme: AppTheme.lightTheme,
      home: const PdfListScreen(),
    );
  }
}
