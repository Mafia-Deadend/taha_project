import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Talks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, // Set the overall theme to dark
        primaryColor: Colors.amber, // Primary color for the app
        scaffoldBackgroundColor: const Color.fromARGB(255, 47, 47, 47), // Background color for all screens
        appBarTheme: const AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 47, 47, 47), // AppBar background color
          foregroundColor: Colors.amber, // AppBar text/icon color
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.amber), // Default text color
          bodyMedium: TextStyle(color: Colors.amber),
          bodySmall: TextStyle(color: Colors.amber),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber, // Button background color
            foregroundColor: const Color.fromARGB(255, 47, 47, 47), // Button text color
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromARGB(255, 47, 47, 47), // TextField background color
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber), // Border color
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber), // Enabled border color
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber), // Focused border color
          ),
          labelStyle: TextStyle(color: Colors.amber), // Label text color
        ),
        iconTheme: const IconThemeData(
          color: Colors.amber, // Icon color
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(token: ''), // Pass token dynamically
      },
    );
  }
}
