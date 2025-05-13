import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secure_talks/globals.dart';
import 'dart:convert';

class HideImageScreen extends StatefulWidget {
  const HideImageScreen({super.key, required this.token});
  final String token;

  @override
  State<HideImageScreen> createState() => _HideImageScreenState();
}

class _HideImageScreenState extends State<HideImageScreen> {
  File? _coverImage;
  File? _secretImage;
  File? _stegoImage; // To store the output stego image
  bool _isLoading = false;
  final TextEditingController _recipientController = TextEditingController();
  List<String> _userSuggestions = []; // List to store user suggestions
  bool _isFetchingUsers = false; // To show a loading indicator while fetching users

  Future<void> _pickImage(bool isCoverImage) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          if (isCoverImage) {
            _coverImage = File(pickedFile.path);
          } else {
            _secretImage = File(pickedFile.path);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _fetchUserSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _userSuggestions = [];
      });
      return;
    }

    setState(() {
      _isFetchingUsers = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/available-users'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body)['available_users'];
        print('API Response: $users'); // Debug print
        setState(() {
          _userSuggestions = users
              .map((user) => user['username'] as String)
              .where((username) => username.toLowerCase().startsWith(query.toLowerCase()))
              .toList();
          print('Filtered Suggestions: $_userSuggestions'); // Debug print
        });
      } else {
        throw Exception('Failed to fetch user suggestions');
      }
    } catch (e) {
      print('Error fetching users: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    } finally {
      setState(() {
        _isFetchingUsers = false;
      });
    }
  }

  Future<void> _hideImage() async {
    if (_coverImage == null || _secretImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both cover and secret images')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _stegoImage = null; // Clear previous stego image
    });

    try {
      final stegoImage = await hideImageInImage(_coverImage!, _secretImage!, widget.token);
      setState(() {
        _stegoImage = stegoImage; // Save the stego image
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image hidden successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<File> hideImageInImage(File coverImage, File secretImage, String token) async {
    final String apiUrl = '$API_BASE_URL/hide-image'; // Replace <your-api-url> with your actual API URL

    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('cover', coverImage.path))
        ..files.add(await http.MultipartFile.fromPath('secret', secretImage.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/stego_image.png');
        await file.writeAsBytes(bytes);
        return file;
      } else {
        throw Exception('Failed to hide image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during API call: $e');
    }
  }

  Future<void> _saveToGallery() async {
    if (_stegoImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stego image to save')),
      );
      return;
    }

    final status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        final directory = await getExternalStorageDirectory();
        final path = '${directory!.path}/stego_image_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(path);
        await file.writeAsBytes(await _stegoImage!.readAsBytes());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to gallery: $path')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
    }
  }

  Future<void> _sendToUser() async {
    if (_stegoImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stego image to send')),
      );
      return;
    }

    final recipient = _recipientController.text.trim();
    if (recipient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipient username')),
      );
      return;
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$API_BASE_URL/send-image'))
        ..headers['Authorization'] = 'Bearer ${widget.token}'
        ..fields['recipient_username'] = recipient
        ..fields['message_type'] = 'stego_image'
        ..files.add(await http.MultipartFile.fromPath('image', _stegoImage!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image sent to $recipient')),
        );
      } else {
        throw Exception('Failed to send image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hide Image in Image'),
      ),
      body: SingleChildScrollView( // Added to make the content scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => _pickImage(true),
                child: const Text('Select Cover Image'),
              ),
              if (_coverImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.file(
                    _coverImage!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ElevatedButton(
                onPressed: () => _pickImage(false),
                child: const Text('Select Secret Image'),
              ),
              if (_secretImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.file(
                    _secretImage!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _hideImage,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Hide Image'),
              ),
              const SizedBox(height: 20),
              if (_stegoImage != null)
                Column(
                  children: [
                    const Text(
                      'Stego Image:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Image.file(
                      _stegoImage!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveToGallery,
                      child: const Text('Save to Gallery'),
                    ),
                    const SizedBox(height: 60),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Suggestions list displayed above the TextField
                        if (_userSuggestions.isNotEmpty)
                          Positioned(
                            bottom: 60, // Adjust this value to position the suggestions above the TextField
                            left: 0,
                            right: 0,
                            child: Material(
                              elevation: 4.0,
                              child: SizedBox(
                                height: 150, // Limit the height of the suggestions list
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _userSuggestions.length,
                                  itemBuilder: (context, index) {
                                    final username = _userSuggestions[index];
                                    return ListTile(
                                      title: Text(username),
                                      onTap: () {
                                        _recipientController.text = username;
                                        setState(() {
                                          _userSuggestions = [];
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        // TextField for recipient username
                        TextField(
                          controller: _recipientController,
                          onChanged: _fetchUserSuggestions, // Fetch suggestions as the user types
                          decoration: const InputDecoration(
                            labelText: 'Recipient Username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _sendToUser,
                      child: const Text('Send to User'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
