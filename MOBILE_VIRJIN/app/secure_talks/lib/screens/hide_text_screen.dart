import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType

// --- Configuration ---
// IMPORTANT: Replace with your actual API base URL
// If running FastAPI locally and Flutter emulator on same machine:
// - Android Emulator: 'http://10.0.2.2:8000'
// - iOS Simulator: 'http://localhost:8000' or 'http://127.0.0.1:8000'
// If running on a physical device, use your computer's network IP.
const String API_BASE_URL = 'https://automatic-doodle-rqpg69qrwp7hp9j9-8000.app.github.dev'; // Example for Android Emulator

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
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _pickCoverImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hide Text in Image'),
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
              TextButton.icon( // Example: Add a way to "save" or "share"
                icon: const Icon(Icons.info_outline),
                label: const Text("Note: Image is displayed. For saving, implement platform-specific file saving."),
                onPressed: () {
                  // Implement saving logic here if desired using path_provider and file operations
                  // Or use share_plus to share the image bytes
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Save/Share functionality not yet implemented in this example.")),
                  );
                },
              )
            ],
          ],
        ),
      ),
    );
  }
}