import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileProvider extends ChangeNotifier {
  String _name = 'New User';
  String _phoneNumber = '';
  String _email = '';
  String? _token;
  int? _userId;
  bool _faceRegistered = false;
  String? _faceImage;
  bool _isLoading = false;

  String get name => _name;
  String get phoneNumber => _phoneNumber;
  String get email => _email;
  String? get token => _token;
  int? get userId => _userId;
  bool get faceRegistered => _faceRegistered;
  String? get faceImage => _faceImage;
  bool get isLoading => _isLoading;

  void setUserData({
    required int id,
    required String phone,
    String? name,
    required String token,
    required bool faceRegistered,
  }) {
    _userId = id;
    _phoneNumber = phone;
    _name = name ?? 'New User';
    _token = token;
    _faceRegistered = faceRegistered;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          _userId = data['id'];
          _phoneNumber = data['phone'];
          _name = data['name'] ?? 'New User';
          _faceImage = data['face_image'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateProfile({required String name, required String phoneNumber, required String email}) {
    _name = name;
    _phoneNumber = phoneNumber;
    _email = email;
    notifyListeners();
  }

  Future<bool> logout() async {
    if (_token == null) return true;

    try {
      final response = await http.get(
        Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          _clearLocalData();
          return true;
        }
      } else if (response.statusCode == 401) {
        // Unauthenticated - just clear local data
        _clearLocalData();
        return true;
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
    
    // Even if API fails, we often want to clear local data to allow user to try logging in again
    _clearLocalData();
    return true;
  }

  void _clearLocalData() {
    _token = null;
    _userId = null;
    _faceImage = null;
    _phoneNumber = '';
    _name = 'New User';
    notifyListeners();
  }
}