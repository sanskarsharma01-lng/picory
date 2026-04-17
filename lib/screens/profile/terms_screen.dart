import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  String _terms = '';
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchTerms();
  }

  Future<void> _fetchTerms() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final token = profileProvider.token;

    try {
      final response = await http.get(
        Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/terms-and-conditions'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            _terms = responseData['data']['data'] ?? 'No terms available';
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = responseData['message'] ?? 'Failed to load terms';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load terms: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = '';
                          });
                          _fetchTerms();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    _terms,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
    );
  }
}
