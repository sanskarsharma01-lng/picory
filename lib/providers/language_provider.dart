import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'en';

  String get languageCode => _languageCode;

  Locale get locale => Locale(_languageCode);

  void changeLanguage(String code) {
    _languageCode = code;
    notifyListeners();
  }

  // Simple translations
  Map<String, Map<String, String>> get translations => {
    'en': {
      'app_name': 'Picory',
      'login': 'Login',
      'mobile_number': 'Mobile Number',
      'send_otp': 'Send OTP',
      'enter_otp': 'Enter OTP',
      'verify': 'Verify',
      'scan_face': 'Scan Face',
      'groups': 'Groups',
      'join_group': 'Join Group',
      'join_via_qr': 'Join via QR Code',
      'join_via_code': 'Join via Unique Code',
      'enter_group_code': 'Enter 4 Alphabet Group Code',
      'my_photos': 'My Photos',
      'all_photos': 'All Photos',
      'home': 'Home',
      'album': 'Album',
      'profile': 'Profile',
      'download': 'Download',
      'share': 'Share',
      'delete': 'Delete',
      'select': 'Select',
      'members': 'Members',
    },
    'hi': {
      'app_name': 'पिकोरी',
      'login': 'लॉगिन',
      'mobile_number': 'मोबाइल नंबर',
      'send_otp': 'OTP भेजें',
      'enter_otp': 'OTP दर्ज करें',
      'verify': 'सत्यापित करें',
      'scan_face': 'चेहरा स्कैन करें',
      'groups': 'समूह',
      'join_group': 'समूह में शामिल हों',
      'join_via_qr': 'QR कोड से जुड़ें',
      'join_via_code': 'यूनिक कोड से जुड़ें',
      'enter_group_code': '4 अक्षर समूह कोड दर्ज करें',
      'my_photos': 'मेरी तस्वीरें',
      'all_photos': 'सभी तस्वीरें',
      'home': 'होम',
      'album': 'एल्बम',
      'profile': 'प्रोफ़ाइल',
      'download': 'डाउनलोड',
      'share': 'शेयर',
      'delete': 'हटाएं',
      'select': 'चुनें',
      'members': 'सदस्य',
    },
  };

  String translate(String key) {
    return translations[_languageCode]?[key] ?? key;
  }
}