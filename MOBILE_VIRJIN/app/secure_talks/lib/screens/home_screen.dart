import 'package:flutter/material.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.username,
    required this.onLogout,
  });

  void _navigateTo(BuildContext context, String title) {
    Navigator.pop(context); // close drawer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to $title')),
    );
    // TODO: Replace with actual navigation logic
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
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Hello, $username!',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => _navigateTo(context, 'Dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Hide Text in Image'),
              onTap: () => _navigateTo(context, 'Hide Text in Image'),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Extract Text from Image'),
              onTap: () => _navigateTo(context, 'Extract Text from Image'),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Hide Image in Image'),
              onTap: () => _navigateTo(context, 'Hide Image in Image'),
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Extract Image from Image'),
              onTap: () => _navigateTo(context, 'Extract Image from Image'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
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
              icon: const Icon(Icons.text_fields),
              label: const Text("Hide Text in Image"),
              onPressed: () => _navigateTo(context, 'Hide Text in Image'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text("Extract Text from Image"),
              onPressed: () => _navigateTo(context, 'Extract Text from Image'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Hide Image in Image"),
              onPressed: () => _navigateTo(context, 'Hide Image in Image'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text("Extract Image from Image"),
              onPressed: () => _navigateTo(context, 'Extract Image from Image'),
            ),
          ],
        ),
      ),
    );
  }
}
