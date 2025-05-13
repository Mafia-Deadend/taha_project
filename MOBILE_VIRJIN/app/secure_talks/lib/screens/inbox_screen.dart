import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:secure_talks/globals.dart';

class InboxScreen extends StatefulWidget {
  final String token;

  const InboxScreen({super.key, required this.token});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  Map<String, List<Map<String, String>>> receivedMessages = {};
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchInboxMessages();
  }

  Future<void> fetchInboxMessages() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/messages'), // Replace with your API URL
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messages = data['received_messages'];

        // Group messages by sender
        final Map<String, List<Map<String, String>>> groupedMessages = {};
        final Map<String, String> senderUsernames = {}; // Map to store sender_id -> username

        for (var message in messages) {
          final senderId = message['sender_id'];
          final senderUsername = message['sender_username'] ?? senderId; // Fallback to senderId
          final messageType = message['message_type'];
          final timestamp = message['timestamp'];

          // Store sender's username or fallback to senderId
          senderUsernames[senderId] = senderUsername;

          if (!groupedMessages.containsKey(senderId)) {
            groupedMessages[senderId] = [];
          }

          groupedMessages[senderId]!.add({
            'message_type': messageType,
            'timestamp': timestamp,
          });
        }

        setState(() {
          receivedMessages = groupedMessages.map((senderId, messages) {
            return MapEntry(senderUsernames[senderId] ?? senderId, messages);
          });
        });
      } else {
        throw Exception('Failed to fetch inbox messages');
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching inbox messages: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            )
          : error.isNotEmpty
              ? Center(
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: receivedMessages.keys.map((senderId) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: Colors.black,
                                title: Text(
                                  'Messages from $senderId',
                                  style: const TextStyle(color: Colors.amber),
                                ),
                                content: SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    itemCount: receivedMessages[senderId]!.length,
                                    itemBuilder: (context, index) {
                                      final message =
                                          receivedMessages[senderId]![index];
                                      return ListTile(
                                        title: Text(
                                          'Type: ${message['message_type']}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        subtitle: Text(
                                          'Date: ${message['timestamp']}',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text(
                                      'Close',
                                      style: TextStyle(color: Colors.amber),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text('Messages from $senderId'), // Updated to use username
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}