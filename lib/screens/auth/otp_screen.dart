import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';

class OtpScreen extends StatefulWidget {
  final String mobileNumber;

  const OtpScreen({super.key, required this.mobileNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length == 6) {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.faceScanRoute);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid 6-digit OTP')),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.translate('verify')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.lock_outline_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Phone',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Code is sent to ${widget.mobileNumber}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: langProvider.translate('enter_otp'),
                  prefixIcon: const Icon(Icons.lock),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: langProvider.translate('verify'),
                onPressed: _isLoading ? null : _verifyOtp,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the code? "),
                  TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: const Text('Resend OTP'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}