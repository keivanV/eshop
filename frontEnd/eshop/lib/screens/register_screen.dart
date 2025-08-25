import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:another_flushbar/flushbar.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _register() async {
    // Trim input values
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();

    // Client-side validation
    if (username.isEmpty || password.isEmpty || email.isEmpty) {
      _showErrorFlushbar('نام کاربری، رمز عبور و ایمیل الزامی است.');
      return;
    }
    if (username.length < 3) {
      _showErrorFlushbar('نام کاربری باید حداقل ۳ کاراکتر باشد.');
      return;
    }
    if (password.length < 6) {
      _showErrorFlushbar('رمز عبور باید حداقل ۶ کاراکتر باشد.');
      return;
    }
    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      _showErrorFlushbar('ایمیل وارد شده معتبر نیست.');
      return;
    }

    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        username,
        password,
        email,
      );

      if (mounted) {
        Flushbar(
          message: "ثبت‌نام با موفقیت انجام شد 🎉",
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.TOP,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          margin: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(12),
        ).show(context);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.dashboard,
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Flushbar(
          message: _translateError(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          flushbarPosition: FlushbarPosition.TOP,
          icon: const Icon(Icons.error, color: Colors.white),
          margin: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(12),
        ).show(context);
      }
    }
  }

  void _showErrorFlushbar(String message) {
    Flushbar(
      message: message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
      flushbarPosition: FlushbarPosition.TOP,
      icon: const Icon(Icons.error, color: Colors.white),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(12),
    ).show(context);
  }

  String _translateError(String error) {
    error = error.toLowerCase();
    debugPrint("Backend error: $error");

    // Map backend error messages to Persian translations
    if (error.contains("username, password, and email are required")) {
      return "نام کاربری، رمز عبور و ایمیل الزامی است.";
    } else if (error.contains("username must be at least 3 characters long")) {
      return "نام کاربری باید حداقل ۳ کاراکتر باشد.";
    } else if (error.contains("password must be at least 6 characters long")) {
      return "رمز عبور باید حداقل ۶ کاراکتر باشد.";
    } else if (error.contains("invalid email format")) {
      return "ایمیل وارد شده معتبر نیست.";
    } else if (error.contains("user exists") ||
        error.contains("duplicate key")) {
      return "نام کاربری قبلاً استفاده شده است.";
    } else if (error.contains("invalid role")) {
      return "نقش انتخاب‌شده نامعتبر است.";
    } else if (error.contains("network error") ||
        error.contains("failed host lookup") ||
        error.contains("timeout")) {
      return "خطا در اتصال به اینترنت. لطفاً اینترنت خود را بررسی کنید.";
    } else if (error.contains("server error") || error.contains("500")) {
      return "خطای سرور! لطفاً بعداً دوباره تلاش کنید.";
    }

    return "خطای ناشناخته رخ داد. لطفاً دوباره تلاش کنید.";
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
                            Icon(
                              FontAwesomeIcons.userPlus,
                              size: 70,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ساخت حساب کاربری',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
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

                            // Username
                            _buildTextField(
                              controller: _usernameController,
                              label: 'نام کاربری',
                              icon: FontAwesomeIcons.user,
                            ),
                            const SizedBox(height: 16),

                            // Email
                            _buildTextField(
                              controller: _emailController,
                              label: 'ایمیل',
                              icon: FontAwesomeIcons.envelope,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            _buildTextField(
                              controller: _passwordController,
                              label: 'رمز عبور',
                              icon: FontAwesomeIcons.lock,
                              isPassword: true,
                            ),
                            const SizedBox(height: 28),

                            // Register Button
                            Container(
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
                                onPressed: _register,
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
                                  'ثبت‌نام',
                                  style: TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Back to Login
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, AppRoutes.login),
                              child: const Text(
                                'بازگشت به ورود',
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
    );
  }

  /// تکست‌فیلد آماده
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
        errorStyle: const TextStyle(
          fontFamily: 'Vazir',
          color: Colors.redAccent,
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
