import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/profile_provider.dart';

class OtpScreen extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const OtpScreen({super.key, required this.arguments});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResendEnabled = false;
  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _isResendEnabled = false;
      _resendCountdown = 30;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _isResendEnabled = true;
        });
        timer.cancel();
      }
    });
  }

  String _getOtp() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    final otp = _getOtp();
    if (otp.length == 6) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/verify-otp'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'user_id': widget.arguments['user_id'].toString(),
            'otp': otp,
          }),
        );

        // Check if response is HTML
        if (response.body.trim().startsWith('<!DOCTYPE html>')) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Server Error: Received HTML instead of JSON. Please check your connection.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        setState(() => _isLoading = false);

        if (response.statusCode == 200 && responseData['success'] == true) {
          final data = responseData['data'];
          final userData = data['user'];

          if (mounted) {
            // Save user data to ProfileProvider
            Provider.of<ProfileProvider>(context, listen: false).setUserData(
              id: userData['id'],
              phone: userData['phone'],
              name: userData['name'],
              token: data['token'],
              faceRegistered: data['face_registered'] ?? false,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP verified successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Navigate based on face registration status
            if (data['face_registered'] == true) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.homeRoute,
                    (route) => false,
              );
            } else {
              Navigator.pushReplacementNamed(context, AppConstants.faceScanRoute);
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Verification failed'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Clear OTP fields on failure
            _clearOtpFields();
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _clearOtpFields();
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid 6-digit OTP'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOtp() async {
    if (!_isResendEnabled) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'phone': widget.arguments['phone']}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _startResendTimer();
        _clearOtpFields();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP resent successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to resend OTP'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
    // Format phone number for display
    String phoneNumber = widget.arguments['phone'] ?? '';
    // Format to show like: +1 987 654 3210
    String formattedPhone = phoneNumber;
    if (phoneNumber.startsWith('+')) {
      if (phoneNumber.length >= 12) {
        formattedPhone = '${phoneNumber.substring(0, 2)} ${phoneNumber.substring(2, 5)} ${phoneNumber.substring(5, 8)} ${phoneNumber.substring(8)}';
      }
    }

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
              const Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Enter the verification code we just sent to your number\n'),
                    TextSpan(
                      text: formattedPhone,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // 6-digit OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 65,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF5E6CE4), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }

                        // Auto-verify when all fields are filled
                        if (index == 5 && value.isNotEmpty && _getOtp().length == 6) {
                          _verifyOtp();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              // Resend section
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    children: [
                      const TextSpan(text: "Didn't receive code? "),
                      TextSpan(
                        text: _isResendEnabled ? 'Resend' : 'Resend in ${_resendCountdown.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _isResendEnabled ? const Color(0xFF5E6CE4) : const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: _isResendEnabled
                            ? (TapGestureRecognizer()..onTap = _resendOtp)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E6CE4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Verify',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
