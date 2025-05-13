import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:secure_talks/globals.dart';

class ExtractTextScreen extends StatefulWidget {
  const ExtractTextScreen({super.key, required this.token});
  final String token;

  @override
  State<ExtractTextScreen> createState() => _ExtractTextScreenState();
}

class _ExtractTextScreenState extends State<ExtractTextScreen> {
  final TextEditingController _resultController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
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

  Future<void> _extractText() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultController.clear();
    });

    try {
      final extractedText = await extractTextFromImage(_selectedImage!.path, widget.token);
      setState(() {
        _resultController.text = extractedText;
      });
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

  Future<String> extractTextFromImage(String imagePath, String token) async {
    final String apiUrl = '$API_BASE_URL/extract-text'; // Replace <your-api-url> with your actual API URL

    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..headers['Authorization'] = 'Bearer $token' // Add the token to the headers
        ..files.add(await http.MultipartFile.fromPath('image', imagePath)); // Add the image file

      // Send the request
      final response = await request.send();

      // Handle the response
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['extracted_text']; // Extract the text from the JSON response
      } else {
        throw Exception('Failed to extract text. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during API call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extract Text from Image'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Select Image'),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null)
              Column(
                children: [
                  Image.file(
                    _selectedImage!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _extractText,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Extract Text'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _resultController,
              maxLines: 5,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Extracted Text',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
