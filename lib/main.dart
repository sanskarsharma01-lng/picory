import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'models/group_model.dart';
import 'models/photo_model.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/auth/face_scan_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/group/group_detail_screen.dart';
import 'screens/group/qr_scanner_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/photo/photo_view_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/terms_screen.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppConstants.splashRoute,
            builder: (context, child) {
              return ConnectivityWrapper(child: child!);
            },
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppConstants.splashRoute:
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );

                case AppConstants.loginRoute:
                  return MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  );

                case AppConstants.otpRoute:
                  final args = settings.arguments as Map<String, dynamic>;
                  return MaterialPageRoute(
                    builder: (_) => OtpScreen(arguments: args),
                  );

                case AppConstants.faceScanRoute:
                  return MaterialPageRoute(
                    builder: (_) => const FaceScanScreen(),
                  );

                case AppConstants.homeRoute:
                  return MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  );

                case AppConstants.groupDetailRoute:
                  final group = settings.arguments as GroupModel;
                  return MaterialPageRoute(
                    builder: (_) => GroupDetailScreen(group: group),
                  );

                case AppConstants.qrScannerRoute:
                  return MaterialPageRoute(
                    builder: (_) => const QrScannerScreen(),
                  );

                case AppConstants.photoViewRoute:
                  final args = settings.arguments as Map<String, dynamic>;
                  return MaterialPageRoute(
                    builder: (_) => PhotoViewScreen(
                      photo: args['photo'] as PhotoModel,
                      photos: args['photos'] as List<PhotoModel>,
                      initialIndex: args['initialIndex'] as int,
                    ),
                  );

                case AppConstants.editProfileRoute:
                  return MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  );

                case AppConstants.termsRoute:
                  return MaterialPageRoute(
                    builder: (_) => const TermsScreen(),
                  );

                default:
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isOnline = Provider.of<ConnectivityProvider>(context).isOnline;

    return Stack(
      children: [
        child,
        if (!isOnline)
          Material(
            color: Colors.black54,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'No Internet Connection',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your network settings and try again. Some features may not work offline.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // This will trigger a rebuild and re-check connection status
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
