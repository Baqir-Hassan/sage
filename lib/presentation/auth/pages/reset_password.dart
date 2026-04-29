import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sage/data/sources/auth/auth_api_service.dart';
import 'package:sage/presentation/auth/pages/singin.dart';
import 'package:sage/service_locator.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordReset = false;

  @override
  void initState() {
    super.initState();
    _tokenController.text = widget.initialToken ?? _tokenFromUrl();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Request a reset link, then paste the token from your email to set a new password.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Email",
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _requestResetLink,
              child: const Text("Send Reset Link"),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Reset Token",
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "New Password",
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReset,
              child: Text(_isLoading ? "Submitting..." : "Reset Password"),
            ),
            if (_isPasswordReset) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => const SigninPage(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text("Continue to Sign In"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _tokenFromUrl() {
    if (!kIsWeb) return "";
    return Uri.base.queryParameters["token"] ?? "";
  }

  Future<void> _requestResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Enter your email first.");
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final result = await sl<AuthApiService>().forgotPassword(email);
    if (!mounted) return;
    result.fold(
      (l) => _showMessage(l.toString()),
      (r) => _showMessage(r.toString()),
    );
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _submitReset() async {
    final token = _tokenController.text.trim();
    final newPassword = _passwordController.text;

    if (token.isEmpty) {
      _showMessage("Enter the reset token first.");
      return;
    }
    if (newPassword.length < 8) {
      _showMessage("New password must be at least 8 characters.");
      return;
    }

    setState(() {
      _isLoading = true;
      _isPasswordReset = false;
    });
    final result = await sl<AuthApiService>().resetPassword(
      token: token,
      newPassword: newPassword,
    );
    if (!mounted) return;
    result.fold(
      (l) => _showMessage(l.toString()),
      (r) {
        setState(() {
          _isPasswordReset = true;
        });
        _showMessage(r.toString());
      },
    );
    setState(() {
      _isLoading = false;
    });
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
