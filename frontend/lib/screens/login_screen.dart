import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:retry/retry.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({required this.onLogin, super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegister = false;
  String _selectedRole = 'student'; // Default role
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final body = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        if (_isRegister) 'name': _nameController.text.trim(),
      };
      final endpoint = _isRegister
          ? '/api/auth/register/$_selectedRole'
          : '/api/auth/login';

      // Retry up to 3 times for transient network errors
      final response = await retry(
        () => ApiService.request(
          endpoint,
          'POST',
          body: body,
          authRequired: false,
        ),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
        retryIf: (e) => e is SocketException || e is TimeoutException,
      );

      // Log response for debugging
      debugPrint('API Response: Status ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        if (data == null || data['token'] == null || data['user'] == null) {
          _showError('Invalid server response: Missing token or user data');
          return;
        }
        final user = data['user'] as Map<String, dynamic>?;
        if (user == null || user['id'] == null || user['role'] == null) {
          _showError('Invalid server response: Missing user id or role');
          return;
        }
        await AuthService.saveTokenAndRole(
          data['token'] as String,
          user['role'] as String,
          userId: user['id'].toString(),
        );
        widget.onLogin();
      } else {
        Map<String, dynamic>? errorData;
        try {
          errorData = response.body.isNotEmpty ? jsonDecode(response.body) as Map<String, dynamic>? : null;
        } catch (e) {
          debugPrint('Failed to parse error response: $e, Body: ${response.body}');
          _showError('Invalid server response');
          return;
        }
        final errorMessage = errorData?['message']?.toString() ?? 'Request failed';
        // Map backend messages for user clarity
        final displayMessage = errorMessage == 'Invalid credentials'
            ? 'Invalid email or password'
            : errorMessage == 'No user found'
                ? 'No account found with this email'
                : errorMessage == 'Student already exists' || errorMessage == 'Teacher already exists'
                    ? 'Email already registered'
                    : errorMessage;
        _showError(displayMessage);
        debugPrint('API Error: $displayMessage, Status: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      _showError('Network error: Please check your internet connection');
      debugPrint('Network Error: $e');
    } on TimeoutException catch (e) {
      _showError('Request timed out: Please try again');
      debugPrint('Timeout Error: $e');
    } on FormatException catch (e) {
      _showError('Invalid server response');
      debugPrint('Format Error: $e, Response Body: ${e.source}');
    } catch (e, stackTrace) {
      _showError('An unexpected error occurred');
      debugPrint('Unexpected Error: $e\nStackTrace: $stackTrace');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isRegister ? 'Register' : 'Login'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isRegister ? 'Create Account' : 'Sign In',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  if (_isRegister)
                    _buildInputField(
                      controller: _nameController,
                      label: 'Name',
                      icon: Icons.person,
                      validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                    ),
                  _buildInputField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
                  ),
                  if (_isRegister)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedRole = newValue!;
                          });
                        },
                        items: <String>['student', 'teacher'].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value[0].toUpperCase() + value.substring(1)),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.group, color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        dropdownColor: Colors.white,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Submitting...'),
                              ],
                            )
                          : Text(_isRegister ? 'Register' : 'Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text.rich(
                      TextSpan(
                        text: _isRegister ? 'Already have an account? ' : 'Need an account? ',
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: _isRegister ? 'Login' : 'Register',
                            style: TextStyle(
                              color: _isRegister ? Colors.blue : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}