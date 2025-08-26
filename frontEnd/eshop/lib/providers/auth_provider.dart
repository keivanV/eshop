import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;
  String? _userId;
  String? _username;
  String? _email;

  String? get token => _token;
  String? get role => _role;
  String? get userId => _userId;
  String? get username => _username;
  String? get email => _email;

  Future<void> updateUserProfile(String email, {String? password}) async {
    if (_userId == null ||
        _userId!.isEmpty ||
        _token == null ||
        _token!.isEmpty) {
      throw Exception('کاربر وارد نشده یا اطلاعات نامعتبر است');
    }
    try {
      debugPrint(
          'Updating user profile: userId=$_userId, email=$email, password=${password != null ? 'provided' : 'null'}');
      final updatedUser = await ApiService.updateUser(
        _userId!, // استفاده از userId به جای username
        _token!,
        email.trim(),
        password: password?.trim(),
      );
      _email = updatedUser['email'] ?? email;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _email ?? '');
      debugPrint('User profile updated: email=$_email');
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    try {
      debugPrint('Logging in: username=$username');
      final response = await ApiService.login(username, password);
      _token = response['token'];
      _role = response['role'];
      _userId = response['userId'];
      _username = response['username'];
      _email = response['email'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token ?? '');
      await prefs.setString('role', _role ?? '');
      await prefs.setString('userId', _userId ?? '');
      await prefs.setString('username', _username ?? '');
      await prefs.setString('email', _email ?? '');
      debugPrint(
          'Login successful: username=$_username, role=$_role, userId=$_userId');
      notifyListeners();
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<void> register(String username, String password, String email,
      {String role = 'user'}) async {
    try {
      debugPrint('Registering: username=$username, email=$email, role=$role');
      final response =
          await ApiService.register(username, password, email, role);
      _token = response['token'];
      _role = response['role'];
      _userId = response['userId'];
      _username = response['username'];
      _email = response['email'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token ?? '');
      await prefs.setString('role', _role ?? '');
      await prefs.setString('userId', _userId ?? '');
      await prefs.setString('username', _username ?? '');
      await prefs.setString('email', _email ?? '');
      debugPrint(
          'Register successful: username=$_username, role=$_role, userId=$_userId');
      notifyListeners();
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    debugPrint('Logging out');
    _token = null;
    _role = null;
    _userId = null;
    _username = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('email');
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token') ||
        !prefs.containsKey('role') ||
        !prefs.containsKey('userId') ||
        !prefs.containsKey('username')) {
      debugPrint('Auto-login failed: Missing required preferences');
      return false;
    }
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    _userId = prefs.getString('userId');
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    debugPrint(
        'Auto-login successful: username=$_username, role=$_role, userId=$_userId');
    notifyListeners();
    return true;
  }

  void updateUsername(String username) {
    debugPrint('Updating username to: $username');
    _username = username;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('username', username);
      notifyListeners();
    });
  }
}
