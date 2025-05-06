import 'package:flutter/material.dart';

class ExtractTextScreen extends StatelessWidget {
  const ExtractTextScreen({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Extract Text from Image Page',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
