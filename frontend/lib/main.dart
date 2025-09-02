import 'package:flutter/material.dart';
import 'package:frontend/screens/auth_wrapper.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/progress_provider.dart'; // New provider for progress tracking

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()), // Added for progress tracking
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SciSpark',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'ComicSans', // Kid-friendly font (preserved)
        scaffoldBackgroundColor: Colors.blue[50], // Subtle background for kid-friendly design
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent, // Button color
            foregroundColor: Colors.white, // Text/icon color
            textStyle: TextStyle(fontFamily: 'ComicSans', fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: AuthWrapper(),
    );
  }
}