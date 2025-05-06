import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({super.key, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> stats = {};
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final url = Uri.parse("https://automatic-doodle-rqpg69qrwp7hp9j9-8000.app.github.dev/userstats"); // Update to your backend URL
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        stats = Map<String, int>.from(json.decode(response.body));
        isLoading = false;
      });
    } else {
      setState(() {
        error = "Failed to fetch stats";
        isLoading = false;
      });
    }
  }

  Widget buildStatCard(String label, int value) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(label),
        trailing: Text(value.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(child: Text(error));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildStatCard("Hide Text", stats['hide_text'] ?? 0),
            buildStatCard("Extract Text", stats['extract_text'] ?? 0),
            buildStatCard("Hide Image", stats['hide_image'] ?? 0),
            buildStatCard("Extract Image", stats['extract_image'] ?? 0),
          ],
        ),
      ),
    );
  }
}
