import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: Text('Welcome, $username'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Text(
                'Hello, $username!',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => _navigateTo(context, DashboardScreen(token: token)),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Hide Text in Image'),
              onTap: () => _navigateTo(context, HideTextScreen(token: token)),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Extract Text from Image'),
              onTap: () => _navigateTo(context, ExtractTextScreen(token: token)),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Hide Image in Image'),
              onTap: () => _navigateTo(context, HideImageScreen(token: token)),
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Extract Image from Image'),
              onTap: () => _navigateTo(context, ExtractImageScreen(token: token)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                onLogout(); // clean up token/session
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
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.dashboard),
              label: const Text("Dashboard"),
              onPressed: () =>
                  _navigateTo(context, DashboardScreen(token: token)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.text_fields),
              label: const Text("Hide Text in Image"),
              onPressed: () =>
                  _navigateTo(context, HideTextScreen(token: token)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text("Extract Text from Image"),
              onPressed: () =>
                  _navigateTo(context, ExtractTextScreen(token: token)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Hide Image in Image"),
              onPressed: () =>
                  _navigateTo(context, HideImageScreen(token: token)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text("Extract Image from Image"),
              onPressed: () =>
                  _navigateTo(context, ExtractImageScreen(token: token)),
            ),
          ],
        ),
      ),
    );
  }
}
