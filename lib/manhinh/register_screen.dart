import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isLoading = false;

  void _showDialog(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: isError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _register() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showDialog("Lỗi", "Không được để trống tất cả các trường!", isError: true);
      return;
    }

    if (password.length < 6) {
      _showDialog("Lỗi", "Mật khẩu phải có ít nhất 6 ký tự!", isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showDialog("Lỗi", "Mật khẩu nhập lại không khớp!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      int result = await _dbHelper.registerUser(username, password);
      setState(() => _isLoading = false);

      if (result > 0) {
        _showDialog("Thành công", "Đăng ký thành công!", isError: false);
        Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (e.toString().contains("UNIQUE constraint failed")) {
        _showDialog("Lỗi", "Tên đăng nhập đã tồn tại!", isError: true);
      } else {
        _showDialog("Lỗi", "Đã xảy ra lỗi: ${e.toString()}", isError: true);
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Đăng Ký",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: "Tên đăng nhập"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Mật khẩu"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Nhập lại mật khẩu"),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _register,
                  child: const Text("Đăng Ký"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
