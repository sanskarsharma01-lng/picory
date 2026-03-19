import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../providers/language_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/custom_button.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _isFaceAligned = false;
  late AnimationController _animationController;
  CameraController? _controller;
  bool _isCameraInitialized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          setState(() => _errorMessage = 'No cameras found');
          return;
        }

        // Use front camera if available
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _controller = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
          
          // Simulate face detection/alignment logic after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _isFaceAligned = true);
            }
          });
        }
      } catch (e) {
        setState(() => _errorMessage = 'Error initializing camera: $e');
      }
    } else {
      setState(() => _errorMessage = 'Camera permission denied');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _scanFace() async {
    if (!_isCameraInitialized || !_isFaceAligned || _controller == null) return;

    setState(() => _isScanning = true);

    try {
      final XFile image = await _controller!.takePicture();
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final token = profileProvider.token;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/face-scan/register'),
      );

      // Add Authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() => _isScanning = false);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face registered successfully!')),
          );

          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: ${response.reasonPhrase}')),
          );
        }
      }
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    
    // Determine ring color
    Color ringColor = Colors.grey;
    if (_isFaceAligned) {
      ringColor = Colors.green;
    }
    if (_isScanning) {
      ringColor = Theme.of(context).colorScheme.primary;
    }

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
              const SizedBox(height: 20),
              Text(
                'Face Verification',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isFaceAligned 
                    ? 'Face aligned! Tap to scan.' 
                    : 'Position your face within the frame',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _isFaceAligned ? Colors.green : Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
                            color: ringColor,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(200),
                          child: _buildCameraPreview(),
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
                                      ringColor.withOpacity(0.8),
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
              const SizedBox(height: 32),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              CustomButton(
                text: _isScanning
                    ? 'Scanning...'
                    : langProvider.translate('scan_face'),
                onPressed: (_isScanning || !_isCameraInitialized || !_isFaceAligned)
                    ? null
                    : _scanFace,
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

  Widget _buildCameraPreview() {
    if (_isCameraInitialized && _controller != null) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: CameraPreview(_controller!),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        color: Colors.grey.withOpacity(0.1),
        child: const Center(
          child: Icon(Icons.error_outline, size: 80, color: Colors.red),
        ),
      );
    }

    return Container(
      color: Colors.grey.withOpacity(0.1),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
