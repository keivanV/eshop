import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;
  String? _userId;

  String? get token => _token;
  String? get role => _role;
  String? get userId => _userId;

  Future<void> login(String username, String password) async {
    try {
      final response = await ApiService.login(username, password);
      _token = response['token'];
      _role = response['role'];
      _userId = response['userId'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('role', _role!);
      await prefs.setString('userId', _userId!);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String username, String password, String email,
      {String role = 'user'}) async {
    try {
      final response =
          await ApiService.register(username, password, email, role);
      _token = response['token'];
      _role = response['role'];
      _userId = response['userId'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('role', _role!);
      await prefs.setString('userId', _userId!);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token') ||
        !prefs.containsKey('role') ||
        !prefs.containsKey('userId')) {
      return false;
    }
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    _userId = prefs.getString('userId');
    notifyListeners();
    return true;
  }
}
