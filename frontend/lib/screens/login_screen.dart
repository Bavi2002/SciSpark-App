import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  LoginScreen({required this.onLogin});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegister = false;
  String? _error;

  Future<void> _submit() async {
    try {
      final body = {
        'email': _emailController.text,
        'password': _passwordController.text,
        if (_isRegister) 'name': _nameController.text,
      };
      final response = await ApiService.request(
        _isRegister ? '/api/student/register' : '/api/student/login',
        'POST',
        body: body,
        authRequired: false,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await AuthService.saveToken(data['token']);
        widget.onLogin();
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'];
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Register' : 'Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            if (_isRegister) TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _submit, child: Text(_isRegister ? 'Register' : 'Login')),
            TextButton(
              onPressed: () => setState(() => _isRegister = !_isRegister),
              child: Text(_isRegister ? 'Switch to Login' : 'Switch to Register'),
            ),
          ],
        ),
      ),
    );
  }
}