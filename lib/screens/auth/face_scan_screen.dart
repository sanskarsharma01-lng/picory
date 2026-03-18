import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _scanFace() async {
    setState(() => _isScanning = true);

    await Future.delayed(const Duration(seconds: 3));

    setState(() => _isScanning = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Face scan successful!')),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.translate('scan_face')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Face Verification',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Position your face within the frame',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 280,
                        height: 350,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isScanning
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(200),
                          child: Container(
                            color: Colors.grey.withOpacity(0.1),
                            child: Icon(
                              Icons.face_rounded,
                              size: 150,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                      if (_isScanning)
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Positioned(
                              top: _animationController.value * 300,
                              child: Container(
                                width: 280,
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: _isScanning ? 'Scanning...' : langProvider.translate('scan_face'),
                onPressed: _isScanning ? null : _scanFace,
                isLoading: _isScanning,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isScanning
                    ? null
                    : () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppConstants.homeRoute,
                  );
                },
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}