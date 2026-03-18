import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  String _name = 'John Doe';
  String _phoneNumber = '+91 9876543210';
  String _email = 'john.doe@example.com';

  String get name => _name;
  String get phoneNumber => _phoneNumber;
  String get email => _email;

  void updateProfile({required String name, required String phoneNumber, required String email}) {
    _name = name;
    _phoneNumber = phoneNumber;
    _email = email;
    notifyListeners();
  }
}