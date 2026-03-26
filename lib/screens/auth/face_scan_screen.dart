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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  CameraController? _controller;
  bool _isCameraInitialized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
    _pulseController.dispose();
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
            const SnackBar(
              content: Text('Face registered successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${response.reasonPhrase}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    size: 24,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Title
              Text(
                'Face Scan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'Please position your face securely within the frame to verify your identity.',
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              // Security note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: const Color(0xFF5E6CE4),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Secure & Encrypted',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Camera preview with frame
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer frame
                      Container(
                        width: 300,
                        height: 380,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: _isFaceAligned
                                ? const Color(0xFF5E6CE4)
                                : const Color(0xFFE5E7EB),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isFaceAligned
                                  ? const Color(0xFF5E6CE4).withOpacity(0.3)
                                  : Colors.transparent,
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(29),
                          child: _buildCameraPreview(),
                        ),
                      ),
                      // Animated scanning line
                      if (!_isScanning && !_isFaceAligned)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 300,
                              height: 380,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: const Color(0xFF5E6CE4).withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: _pulseController.value * 380,
                                    child: Container(
                                      width: 300,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            const Color(0xFF5E6CE4),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      // Face alignment indicator
                      if (_isFaceAligned && !_isScanning)
                        Container(
                          width: 300,
                          height: 380,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: const Color(0xFF5E6CE4),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5E6CE4).withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF5E6CE4).withOpacity(0.2),
                                border: Border.all(
                                  color: const Color(0xFF5E6CE4),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Color(0xFF5E6CE4),
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      // Loading indicator while scanning
                      if (_isScanning)
                        Container(
                          width: 300,
                          height: 380,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Scanning face...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Error message if any
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Scan Face Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isScanning || !_isCameraInitialized || !_isFaceAligned)
                      ? null
                      : _scanFace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E6CE4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                  ),
                  child: _isScanning
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Scan Face',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Skip button
              Center(
                child: TextButton(
                  onPressed: _isScanning
                      ? null
                      : () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppConstants.homeRoute,
                    );
                  },
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isCameraInitialized && _controller != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: CameraPreview(_controller!),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            Text(
              'Camera unavailable',
              style: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5E6CE4)),
        ),
      ),
    );
  }
}