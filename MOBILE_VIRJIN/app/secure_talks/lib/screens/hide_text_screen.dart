import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:permission_handler/permission_handler.dart'; // For permission handling
import 'package:path_provider/path_provider.dart'; // For storing files locally
import 'package:secure_talks/globals.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'dart:convert'; // For jsonDecode
import 'package:url_launcher/url_launcher.dart';

class HideTextScreen extends StatefulWidget {
  final String token;
  const HideTextScreen({super.key, required this.token});

  @override
  State<HideTextScreen> createState() => _HideTextScreenState();
}

class _HideTextScreenState extends State<HideTextScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _coverImageFile;
  Uint8List? _stegoImageBytes;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  List<String> _userSuggestions = [];
  bool _isLoading = false;
  bool _isFetchingUsers = false;
  String? _errorMessage;
  String? _successMessage;

  // Permission Request
  Future<void> requestStoragePermission() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      setState(() {
        _errorMessage = "Storage permission is required to save the image.";
      });
    }
  }

  // Pick cover image from gallery
  Future<void> _pickCoverImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _coverImageFile = pickedFile;
          _stegoImageBytes = null; // Clear previous result
          _errorMessage = null;
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image: $e";
      });
    }
  }

  // Hide text in the image using the backend API
  Future<void> _hideTextInImage() async {
    if (_coverImageFile == null) {
      setState(() {
        _errorMessage = "Please select a cover image.";
      });
      return;
    }
    if (_textController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter text to hide.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _stegoImageBytes = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$API_BASE_URL/hide-text'),
      );

      // Add token to headers
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      // Add text
      request.fields['text'] = _textController.text;

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // This 'image' must match the FastAPI parameter name
          _coverImageFile!.path,
          contentType: MediaType('image', _coverImageFile!.path.split('.').last), // e.g. image/png
        ),
      );

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final bytes = await streamedResponse.stream.toBytes();
        setState(() {
          _stegoImageBytes = bytes;
          _successMessage = "Text hidden successfully! Result shown below.";
        });
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        print("Error from server: $responseBody");
        setState(() {
          _errorMessage =
              "Error hiding text: ${streamedResponse.reasonPhrase} (Status: ${streamedResponse.statusCode}). Details: $responseBody";
        });
      }
    } catch (e) {
      print("Exception during API call: $e");
      setState(() {
        _errorMessage = "An error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save image to gallery or share
  Future<void> saveImageToGallery(Uint8List imageBytes) async {
    await requestStoragePermission();  // Request permission first

    if (_errorMessage != null) return;

    final directory = await getExternalStorageDirectory();
    final path = '${directory!.path}/stego_${DateTime.now().millisecondsSinceEpoch}.png';

    final file = File(path);
    await file.writeAsBytes(imageBytes);

    print('Image saved to: $path');
    setState(() {
      _successMessage = 'Image saved to gallery!';
    });
  }

  // Share image
  Future<void> shareImage(Uint8List imageBytes) async {
    await requestStoragePermission();  // Request permission first

    if (_errorMessage != null) return;

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/stego_image.png');
    await file.writeAsBytes(imageBytes);

    // Use share_plus to share the image
    
  }

  // Save image to gallery
  Future<void> _saveToGallery() async {
    if (_stegoImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stego image to save')),
      );
      return;
    }

    await requestStoragePermission(); // Request permission first

    if (_errorMessage != null) return;

    final directory = await getExternalStorageDirectory();
    final path = '${directory!.path}/stego_${DateTime.now().millisecondsSinceEpoch}.png';

    final file = File(path);
    await file.writeAsBytes(_stegoImageBytes!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved to gallery: $path')),
    );
  }

  // Fetch user suggestions
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
        setState(() {
          _userSuggestions = users
              .map((user) => user['username'] as String)
              .where((username) => username.toLowerCase().startsWith(query.toLowerCase()))
              .toList();
        });
      } else {
        throw Exception('Failed to fetch user suggestions');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    } finally {
      setState(() {
        _isFetchingUsers = false;
      });
    }
  }

  // Send image to user
  Future<void> _sendToUser() async {
    if (_stegoImageBytes == null) {
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
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/stego_image.png');
      await file.writeAsBytes(_stegoImageBytes!);

      final request = http.MultipartRequest('POST', Uri.parse('$API_BASE_URL/send-image'))
        ..headers['Authorization'] = 'Bearer ${widget.token}'
        ..fields['recipient_username'] = recipient
        ..fields['message_type'] = 'stego_image'
        ..files.add(await http.MultipartFile.fromPath('image', file.path));

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

  Future<void> _sendViaGmail(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/stego_image.png');
    await file.writeAsBytes(imageBytes);

    final emailUri = Uri(
      scheme: 'mailto',
      path: '', // Add recipient email here if needed
      query: Uri.encodeFull(
        'subject=Stego Image&body=Please find the attached stego image.&attachment=${file.path}',
      ),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Gmail')),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hide Text in Image'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color.fromARGB(255, 150, 2, 196)),
              child: Text(
                'Hello, ${userProvider.username}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'times new roman',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text(
                'Home',
                style: TextStyle(
                  color: Color.fromARGB(255, 135, 3, 135),
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color.fromARGB(255, 135, 3, 135),
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                userProvider.clearUser();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Cover Image Selection ---
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.center,
                child: _coverImageFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_search, size: 50),
                          Text('Tap to select cover image'),
                        ],
                      )
                    : Image.file(
                        File(_coverImageFile!.path),
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Text Input ---
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text to Hide',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // --- Action Button ---
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility_off),
              label: const Text('Hide Text'),
              onPressed: (_isLoading || _coverImageFile == null) ? null : _hideTextInImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // --- Loading Indicator ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // --- Error Message ---
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

            // --- Success Message ---
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

            // --- Stego Image Display ---
            if (_stegoImageBytes != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Steganographed Image:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Image.memory(
                  _stegoImageBytes!,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text("Save Image"),
                    onPressed: () {
                      if (_stegoImageBytes != null) {
                        saveImageToGallery(_stegoImageBytes!);
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text("Share Image"),
                    onPressed: () {
                      if (_stegoImageBytes != null) {
                        shareImage(_stegoImageBytes!);
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.email),
                    label: const Text("Send via Gmail"),
                    onPressed: () {
                      if (_stegoImageBytes != null) {
                        _sendViaGmail(_stegoImageBytes!);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _recipientController,
                onChanged: _fetchUserSuggestions,
                decoration: const InputDecoration(
                  labelText: 'Recipient Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _sendToUser,
                child: const Text('Send to User'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
