import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sage/data/sources/auth/auth_api_service.dart';
import 'package:sage/presentation/auth/pages/singin.dart';
import 'package:sage/service_locator.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, this.initialToken, this.prefilledEmail});

  final String? initialToken;
  final String? prefilledEmail;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.prefilledEmail ?? "";
    _tokenController.text = widget.initialToken ?? _tokenFromUrl();
    if (_tokenController.text.trim().isNotEmpty) {
      _verifyToken();
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Paste your verification token or open this page from the email link.",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Verification Token",
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyToken,
              child: Text(_isLoading ? "Verifying..." : "Verify Email"),
            ),
            const SizedBox(height: 24),
            const Text(
              "Didn't get the email? Check spam/junk folder, then resend verification.",
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Email",
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _resendVerification,
              child: const Text("Resend Verification"),
            ),
            const SizedBox(height: 16),
            if (_isVerified)
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
        ),
      ),
    );
  }

  String _tokenFromUrl() {
    if (!kIsWeb) return "";
    return Uri.base.queryParameters["token"] ?? "";
  }

  Future<void> _verifyToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showMessage("Enter the verification token first.");
      return;
    }
    setState(() {
      _isLoading = true;
      _isVerified = false;
    });
    final result = await sl<AuthApiService>().verifyEmail(token);
    if (!mounted) return;
    result.fold(
      (l) => _showMessage(l.toString()),
      (r) {
        setState(() {
          _isVerified = true;
        });
        _showMessage(r.toString());
      },
    );
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _resendVerification() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Enter your email first.");
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final result = await sl<AuthApiService>().resendVerification(email);
    if (!mounted) return;
    result.fold(
      (l) => _showMessage(l.toString()),
      (r) => _showMessage(r.toString()),
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
