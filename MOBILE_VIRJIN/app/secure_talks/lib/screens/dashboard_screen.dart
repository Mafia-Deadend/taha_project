import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:secure_talks/globals.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({super.key, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> stats = {};
  String username = '';
  bool isLoading = true;
  String error = '';
  String usernamed = '';

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final url = Uri.parse("$API_BASE_URL/user-stats");
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);

        Map<String, int> parsedStats = {};
        data.forEach((key, value) {
          if (value is int) {
            parsedStats[key] = value;
          }
        });

        setState(() {
          usernamed = data['username'] ?? 'User';
         
          stats = parsedStats;
          isLoading = false;
        });

      } catch (e) {
        setState(() {
          error = "Error parsing response: $e";
          isLoading = false;
        });
      }
    } else {
      setState(() {
        error = "Failed to fetch stats. Status: ${response.statusCode}";
        isLoading = false;
      });
    }
  }

  Widget buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  username: userProvider.username,
                  token: userProvider.token,
                  onLogout: () {
                    userProvider.clearUser();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              ),
            );
          },
        ),
        title: const Text('📊 Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard for User :  $usernamed',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            buildStatCard("Hide Text", stats['hide_text'] ?? 0, Icons.visibility_off, Colors.teal),
                            buildStatCard("Extract Text", stats['extract_text'] ?? 0, Icons.visibility, Colors.orange),
                            buildStatCard("Hide Image", stats['hide_image'] ?? 0, Icons.image_not_supported, Colors.blue),
                            buildStatCard("Extract Image", stats['extract_image'] ?? 0, Icons.image, Colors.pink),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
