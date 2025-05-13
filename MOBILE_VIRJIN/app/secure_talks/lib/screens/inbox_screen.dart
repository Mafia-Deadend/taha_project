import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sender_messages_screen.dart';

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

        // Group messages by sender username
        final Map<String, List<Map<String, String>>> groupedMessages = {};
        for (var message in messages) {
          final senderUsername = message['sender_username']; // Use sender_username
          final messageType = message['message_type'];
          final timestamp = message['timestamp'];

          if (!groupedMessages.containsKey(senderUsername)) {
            groupedMessages[senderUsername] = [];
          }

          groupedMessages[senderUsername]!.add({
            'message_type': messageType,
            'timestamp': timestamp,
          });
        }

        setState(() {
          receivedMessages = groupedMessages;
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
                  children: receivedMessages.keys.map((senderUsername) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SenderMessagesScreen(
                                  senderUsername: senderUsername,
                                  messages: receivedMessages[senderUsername]!,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Messages from $senderUsername\nLast: ${receivedMessages[senderUsername]!.last['timestamp']}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}