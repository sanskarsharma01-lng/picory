import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  String _name = 'New User';
  String _phoneNumber = '';
  String _email = '';
  String? _token;
  int? _userId;
  bool _faceRegistered = false;
  String? _faceImage;
  bool _isLoading = false;
  bool _isInitialized = false;

  String get name => _name;
  String get phoneNumber => _phoneNumber;
  String get email => _email;
  String? get token => _token;
  int? get userId => _userId;
  bool get faceRegistered => _faceRegistered;
  String? get faceImage => _faceImage;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  ProfileProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getInt('user_id');
    _name = prefs.getString('name') ?? 'New User';
    _phoneNumber = prefs.getString('phone') ?? '';
    _faceRegistered = prefs.getBool('face_registered') ?? false;
    _faceImage = prefs.getString('face_image');
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) prefs.setString('token', _token!);
    if (_userId != null) prefs.setInt('user_id', _userId!);
    prefs.setString('name', _name);
    prefs.setString('phone', _phoneNumber);
    prefs.setBool('face_registered', _faceRegistered);
    if (_faceImage != null) prefs.setString('face_image', _faceImage!);
  }

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
    _saveToPrefs();
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
          _saveToPrefs();
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
    _saveToPrefs();
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
          await _clearLocalData();
          return true;
        }
      } else if (response.statusCode == 401) {
        await _clearLocalData();
        return true;
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
    
    await _clearLocalData();
    return true;
  }

  Future<void> _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _token = null;
    _userId = null;
    _faceImage = null;
    _phoneNumber = '';
    _name = 'New User';
    _faceRegistered = false;
    notifyListeners();
  }
}