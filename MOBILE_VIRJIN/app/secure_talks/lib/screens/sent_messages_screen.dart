import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

        // Group messages by recipient
        final Map<String, List<Map<String, String>>> groupedMessages = {};
        for (var message in messages) {
          final recipientId = message['recipient_id'];
          final messageType = message['message_type'];
          final timestamp = message['timestamp'];

          if (!groupedMessages.containsKey(recipientId)) {
            groupedMessages[recipientId] = [];
          }

          groupedMessages[recipientId]!.add({
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
                  children: sentMessages.keys.map((recipientId) {
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
                                  'Messages to $recipientId',
                                  style: const TextStyle(color: Colors.amber),
                                ),
                                content: SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    itemCount: sentMessages[recipientId]!.length,
                                    itemBuilder: (context, index) {
                                      final message =
                                          sentMessages[recipientId]![index];
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
                          child: Text('Messages to $recipientId'),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}