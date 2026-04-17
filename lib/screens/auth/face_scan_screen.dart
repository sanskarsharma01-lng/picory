import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../providers/profile_provider.dart';

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

        final frontCamera = cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _controller = CameraController(
          frontCamera,
          ResolutionPreset.high, 
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);

          // In a real app, you'd use a face detection library here.
          // For now, we simulate alignment after 2 seconds.
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
    // CRITICAL: Prevent proceeding if face is not detected/aligned
    if (!_isFaceAligned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please align your face properly within the frame'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_isCameraInitialized || _controller == null) {
      setState(() => _errorMessage = 'Camera not ready. Please try again.');
      return;
    }

    setState(() => _isScanning = true);

    try {
      final XFile image = await _controller!.takePicture();
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final token = profileProvider.token;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/face-scan/register'),
      );

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
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
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
          // If server says face was not detected properly
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Face not detected properly. Please try again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Reset alignment so user has to try again
            setState(() => _isFaceAligned = false);
            // Wait 2 seconds before "simulating" alignment again
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _isFaceAligned = true);
            });
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
              const Text(
                'Face Scan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please position your face securely within the frame to verify your identity.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: Color(0xFF5E6CE4),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Secure & Encrypted',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: _buildCameraFrame(),
                ),
              ),
              const SizedBox(height: 32),
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
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isScanning || !_isCameraInitialized)
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
              // REMOVED: Skip for now button - user MUST scan face
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraFrame() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 300,
          height: 380,
          decoration: BoxDecoration(
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
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF5E6CE4),
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
        if (_isFaceAligned && !_isScanning)
          Container(
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
    );
  }

  Widget _buildCameraPreview() {
    if (_isCameraInitialized && _controller != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double cameraAspectRatio = _controller!.value.aspectRatio;
          
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth / cameraAspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          );
        },
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            const Text(
              'Camera unavailable',
              style: TextStyle(
                color: Color(0xFF6B7280),
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
