import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:secure_talks/globals.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class ExtractImageScreen extends StatefulWidget {
  const ExtractImageScreen({super.key, required this.token});
  final String token;

  @override
  State<ExtractImageScreen> createState() => _ExtractImageScreenState();
}

class _ExtractImageScreenState extends State<ExtractImageScreen> {
  File? _stegoImage;
  File? _extractedImage;
  bool _isLoading = false;

  Future<void> _pickStegoImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _stegoImage = File(pickedFile.path);
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

  Future<void> _extractImage() async {
    if (_stegoImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a stego image first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final extractedImage = await extractImageFromStego(_stegoImage!, widget.token);
      setState(() {
        _extractedImage = extractedImage;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image extracted successfully!')),
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

  Future<File> extractImageFromStego(File stegoImage, String token) async {
    final String apiUrl = '$API_BASE_URL/extract-image';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('stego', stegoImage.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/extracted_image.png');
        await file.writeAsBytes(bytes);
        return file;
      } else {
        throw Exception('Failed to extract image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during API call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extract Image from Stego Image'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickStegoImage,
              child: const Text('Select Stego Image'),
            ),
            if (_stegoImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.file(
                  _stegoImage!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _extractImage,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Extract Image'),
            ),
            const SizedBox(height: 16),
            if (_extractedImage != null)
              Column(
                children: [
                  const Text(
                    'Extracted Image:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Image.file(
                    _extractedImage!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
