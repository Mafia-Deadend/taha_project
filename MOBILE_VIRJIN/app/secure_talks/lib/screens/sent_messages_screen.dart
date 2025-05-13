import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:secure_talks/screens/recipient_messages_screen.dart';

import 'package:secure_talks/globals.dart';

class SentMessagesScreen extends StatefulWidget {
  final String token;

  const SentMessagesScreen({super.key, required this.token});

  @override
  State<SentMessagesScreen> createState() => _SentMessagesScreenState();
}

class _SentMessagesScreenState extends State<SentMessagesScreen> {
  Map<String, List<Map<String, String>>> sentMessages = {};
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchSentMessages();
  }

  Future<void> fetchSentMessages() async {
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
        final List<dynamic> messages = data['sent_messages'];

        // Group messages by recipient username
        final Map<String, List<Map<String, String>>> groupedMessages = {};
        for (var message in messages) {
          final recipientUsername = message['recipient_username']; // Use recipient_username
          final messageType = message['message_type'];
          final timestamp = message['timestamp'];

          if (!groupedMessages.containsKey(recipientUsername)) {
            groupedMessages[recipientUsername] = [];
          }

          groupedMessages[recipientUsername]!.add({
            'message_type': messageType,
            'timestamp': timestamp,
          });
        }

        setState(() {
          sentMessages = groupedMessages;
        });
      } else {
        throw Exception('Failed to fetch sent messages');
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching sent messages: $e';
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
        title: const Text('Sent Messages'),
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
                  children: sentMessages.keys.map((recipientUsername) {
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
                                builder: (_) => RecipientMessagesScreen(
                                  recipientUsername: recipientUsername,
                                  messages: sentMessages[recipientUsername]!,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Messages to $recipientUsername',
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