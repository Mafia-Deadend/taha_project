import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _username = '';
  String _token = '';

  String get username => _username;
  String get token => _token;

  void setUser(String username, String token) {
    _username = username;
    _token = token;
    notifyListeners();
  }

  void clearUser() {
    _username = '';
    _token = '';
    notifyListeners();
  }
}