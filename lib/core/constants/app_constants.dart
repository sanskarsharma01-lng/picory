class AppConstants {
  static const String appName = 'Picory';

  // Navigation Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String faceScanRoute = '/face-scan';
  static const String homeRoute = '/home';
  static const String groupDetailRoute = '/group-detail';
  static const String photoViewRoute = '/photo-view';

  // Languages
  static const Map<String, String> languages = {
    'en': 'English',
    'hi': 'हिंदी',
  };

  // Dummy Image URLs
  static const String dummyGroupImage = 'https://via.placeholder.com/150';
  static const String dummyPhotoImage = 'https://via.placeholder.com/300';
  static const String dummyProfileImage = 'https://via.placeholder.com/200';
}