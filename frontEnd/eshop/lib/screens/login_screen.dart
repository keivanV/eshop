import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:another_flushbar/flushbar.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// نمایش پیام خطا با Flushbar
  void _showErrorMessage(String message) {
    Flushbar(
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      backgroundGradient: LinearGradient(
        colors: [Colors.red.shade400, Colors.red.shade600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      flushbarPosition: FlushbarPosition.TOP,
      icon: const Icon(Icons.error, size: 32, color: Colors.white),
      messageText: Text(
        message,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 500),
    ).show(context);
  }

  /// متد ورود
  void _login() async {
    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "خطا در برقراری ارتباط. لطفا دوباره تلاش کنید.";

        if (e.toString().contains("Invalid credentials")) {
          errorMessage = "نام کاربری یا رمز عبور اشتباه است.";
        } else if (e.toString().contains("timeout")) {
          errorMessage = "اتصال برقرار نشد. اینترنت خود را بررسی کنید.";
        }

        _showErrorMessage(errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 151, 151, 151), Color.fromARGB(255, 44, 44, 44)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                      vertical: size.height * 0.05,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo
                              ScaleTransition(
                                scale: Tween<double>(begin: 0.8, end: 1.1)
                                    .animate(CurvedAnimation(
                                  parent: _animationController,
                                  curve: Curves.easeInOut,
                                )),
                                child: Icon(
                                  FontAwesomeIcons.shoppingBag,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'خریدآسان',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                  fontFamily: 'Vazir',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 24),

                              // Username Field
                              _buildTextField(
                                controller: _usernameController,
                                label: 'نام کاربری',
                                icon: FontAwesomeIcons.user,
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              _buildTextField(
                                controller: _passwordController,
                                label: 'رمز عبور',
                                icon: FontAwesomeIcons.lock,
                                isPassword: true,
                              ),
                              const SizedBox(height: 28),

                              // Login Button
                              GestureDetector(
                                onTapDown: (_) {
                                  _animationController.reverse().then((value) {
                                    _animationController.forward();
                                    _login();
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xff11998e),
                                        Color(0xff38ef7d),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'ورود',
                                      style: TextStyle(
                                        fontFamily: 'Vazir',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Register Button
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.register),
                                child: const Text(
                                  'ثبت‌نام',
                                  style: TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ویجت آماده برای تکست‌فیلدها
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Vazir',
          color: Colors.white,
        ),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? FontAwesomeIcons.eye
                      : FontAwesomeIcons.eyeSlash,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Vazir',
        color: Colors.white,
      ),
      textDirection: TextDirection.rtl,
    );
  }
}
