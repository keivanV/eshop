import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    debugPrint('UserManagementScreen initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsers();
    });
  }

  Future<void> _fetchUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      debugPrint('Fetching users...');
      final users = await ApiService.getUsers(authProvider.token!);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _formatErrorMessage(e.toString());
        });
      }
      debugPrint('Error fetching users: $e');
    }
  }

  String _formatErrorMessage(String error) {
    if (error.contains('403')) {
      return 'عدم دسترسی: لطفاً با حساب مدیر وارد شوید';
    } else if (error.contains('404')) {
      return 'کاربری یافت نشد';
    } else {
      return error.replaceFirst('Exception: ', '');
    }
  }

  Future<void> _updateUser(
      User user, String newUsername, String newEmail) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await ApiService.updateUser(
        user.id,
        authProvider.token!,
        newUsername,
        newEmail,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'کاربر با موفقیت به‌روزرسانی شد',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        await _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در به‌روزرسانی کاربر: ${_formatErrorMessage(e.toString())}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await ApiService.deleteUser(userId, authProvider.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'کاربر با موفقیت حذف شد',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        await _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در حذف کاربر: ${_formatErrorMessage(e.toString())}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await ApiService.changeUserRole(userId, newRole, authProvider.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'نقش کاربر به $newRole تغییر کرد',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        await _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در تغییر نقش کاربر: ${_formatErrorMessage(e.toString())}',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorWidget()
              : _buildUserList(context),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'خطا در بارگذاری کاربران: $_errorMessage',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 16, fontFamily: 'Vazir'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _fetchUsers();
            },
            child:
                const Text('تلاش مجدد', style: TextStyle(fontFamily: 'Vazir')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            return _buildUserCard(context, user);
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user) {
    final usernameController = TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();
    String selectedRole = user.role;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'کاربر: ${user.username}',
                  style: const TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                  onPressed: () {
                    _showDeleteConfirmationDialog(context, user);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'نام کاربری',
                      labelStyle: TextStyle(fontFamily: 'Vazir'),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً نام کاربری را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'ایمیل',
                      labelStyle: TextStyle(fontFamily: 'Vazir'),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً ایمیل را وارد کنید';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'لطفاً ایمیل معتبر وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'نقش کاربر',
                      labelStyle: TextStyle(fontFamily: 'Vazir'),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child:
                            Text('مدیر', style: TextStyle(fontFamily: 'Vazir')),
                      ),
                      DropdownMenuItem(
                        value: 'warehouse_manager',
                        child: Text('مدیر انبار',
                            style: TextStyle(fontFamily: 'Vazir')),
                      ),
                      DropdownMenuItem(
                        value: 'delivery_agent',
                        child: Text('مامور تحویل',
                            style: TextStyle(fontFamily: 'Vazir')),
                      ),
                      DropdownMenuItem(
                        value: 'user',
                        child: Text('کاربر عادی',
                            style: TextStyle(fontFamily: 'Vazir')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null && value != selectedRole) {
                        _showChangeRoleConfirmationDialog(context, user, value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        _updateUser(
                          user,
                          usernameController.text,
                          emailController.text,
                        );
                      }
                    },
                    child: const Text('به‌روزرسانی',
                        style: TextStyle(fontFamily: 'Vazir')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
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

  void _showDeleteConfirmationDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف', style: TextStyle(fontFamily: 'Vazir')),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید کاربر "${user.username}" را حذف کنید؟',
          style: const TextStyle(fontFamily: 'Vazir'),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(fontFamily: 'Vazir')),
          ),
          TextButton(
            onPressed: () {
              _deleteUser(user.id);
              Navigator.pop(context);
            },
            child: const Text('حذف',
                style: TextStyle(fontFamily: 'Vazir', color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleConfirmationDialog(
      BuildContext context, User user, String newRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید تغییر نقش',
            style: TextStyle(fontFamily: 'Vazir')),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید نقش "${user.username}" را به "$newRole" تغییر دهید؟',
          style: const TextStyle(fontFamily: 'Vazir'),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(fontFamily: 'Vazir')),
          ),
          TextButton(
            onPressed: () {
              _changeUserRole(user.id, newRole);
              Navigator.pop(context);
            },
            child: const Text('تأیید',
                style: TextStyle(fontFamily: 'Vazir', color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}
