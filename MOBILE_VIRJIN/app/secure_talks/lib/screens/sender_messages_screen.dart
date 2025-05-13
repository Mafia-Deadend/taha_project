import 'package:flutter/material.dart';

class SenderMessagesScreen extends StatelessWidget {
  final String senderUsername;
  final List<Map<String, String>> messages;

  const SenderMessagesScreen({
    super.key,
    required this.senderUsername,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Messages from $senderUsername'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return Card(
            color: const Color.fromARGB(255, 47, 47, 47),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                'Type: ${message['message_type']}',
                style: const TextStyle(color: Colors.amber),
              ),
              subtitle: Text(
                'Date: ${message['timestamp']}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}