import 'dart:math';

import 'package:flutter/material.dart';
import 'package:secure_talks/screens/inbox_screen.dart';
import 'package:secure_talks/screens/sent_messages_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'hide_text_screen.dart';
import 'extract_text_screen.dart';
import 'hide_image_screen.dart';
import 'extract_image_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  final String token;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.username,
    required this.token,
    required this.onLogout,
  });

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Welcome, $username',
          style: const TextStyle(fontSize: 20, fontFamily: 'times new roman'),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color.fromARGB(255, 150, 2, 196)),
              child: Text(
                'Hello, $username!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'times new roman',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text(
                'Dashboard',
                style: TextStyle(
                  color: Color.fromARGB(255, 135, 3, 135),
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _navigateTo(context, DashboardScreen(token: token)),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text(
                'Hide Text in Image',
                style: TextStyle(
                  color: Color.fromARGB(255, 135, 3, 135),
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.enable('smcp')], // Small caps
                ),
              ),
              onTap: () => _navigateTo(context, HideTextScreen(token: token)),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text(
                'Extract Text from Image',
                style: TextStyle(
                  color: Color.fromARGB(255, 135, 3, 135),
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _navigateTo(context, ExtractTextScreen(token: token)),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text(
                'Hide Image in Image',
                style: TextStyle(
                  color: Color.fromARGB(255, 135, 3, 135),
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _navigateTo(context, HideImageScreen(token: token)),
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text(
                'Extract Image from Image',
                style: TextStyle(
                  color: Color.fromARGB(255, 135, 3, 135),
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _navigateTo(context, ExtractImageScreen(token: token)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color.fromARGB(255, 135, 3, 135),
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                onLogout(); // Clean up token/session
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Welcome to the Steganography App!",
              style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 252, 252, 251)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.dashboard),
              label: const Text("Dashboard"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardScreen(token: token),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.text_fields),
              label: const Text("Hide Text in Image"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HideTextScreen(token: token),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text("Extract Text from Image"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExtractTextScreen(token: token),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Hide Image in Image"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HideImageScreen(token: token),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text("Extract Image from Image"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExtractImageScreen(token: token),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Inbox Button
            ElevatedButton.icon(
              icon: const Icon(Icons.inbox),
              label: const Text("Inbox"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                // Navigate to Inbox Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InboxScreen(token: token), // Replace with your InboxScreen
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Sent Messages Button
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text("Sent Messages"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                // Navigate to Sent Messages Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SentMessagesScreen(token: token), // Replace with your SentMessagesScreen
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
