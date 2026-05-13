import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sage/common/widgets/appbar/app_bar.dart';
import 'package:sage/common/widgets/button/basic_app_button.dart';
import 'package:sage/core/configs/assets/app_vectors.dart';
import 'package:sage/core/configs/theme/app_color.dart';
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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _isPasswordReset = false;
  bool _linkSent = false;

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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasToken => _tokenController.text.trim().isNotEmpty;

  String _tokenFromUrl() {
    if (!kIsWeb) return '';
    return Uri.base.queryParameters['token'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: BasicAppBar(
          title: SvgPicture.asset(
            AppVectors.logo,
            height: 40,
            width: 40,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: _hasToken ? _resetForm(context) : _requestForm(context),
        ),
      ),
    );
  }

  // ── Request reset link form ──────────────────────────────────────────────
  Widget _requestForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Recovery Password',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter your email address and we will send you a link to reset your password.',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: AppColors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Enter your email',
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
        ),
        const SizedBox(height: 20),
        if (_linkSent) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reset link sent! Check your inbox and spam folder.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        BasicAppButton(
          title: _isLoading
              ? 'Sending...'
              : _linkSent
                  ? 'Resend Link'
                  : 'Send Reset Link',
          onPressed: _isLoading ? null : _requestResetLink,
          textSize: 22,
          weight: FontWeight.w500,
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Back to Sign In',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Reset password form (token from URL) ─────────────────────────────────
  Widget _resetForm(BuildContext context) {
    if (_isPasswordReset) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.primary,
            size: 72,
          ),
          const SizedBox(height: 24),
          const Text(
            'Password Reset!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your password has been reset successfully. You can now sign in with your new password.',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          BasicAppButton(
            title: 'Sign In',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const SigninPage(),
                ),
                (route) => false,
              );
            },
            textSize: 22,
            weight: FontWeight.w500,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'New Password',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter and confirm your new password below.',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: AppColors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'New Password',
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Confirm New Password',
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
        ),
        const SizedBox(height: 28),
        BasicAppButton(
          title: _isLoading ? 'Resetting...' : 'Reset Password',
          onPressed: _isLoading ? null : _submitReset,
          textSize: 22,
          weight: FontWeight.w500,
        ),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────
  Future<void> _requestResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email first.');
      return;
    }
    setState(() => _isLoading = true);
    final result = await sl<AuthApiService>().forgotPassword(email);
    if (!mounted) return;
    result.fold(
      (l) => _showMessage(l.toString()),
      (r) => setState(() => _linkSent = true),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _submitReset() async {
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return;
    }
    if (password != confirm) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _isPasswordReset = false;
    });

    final result = await sl<AuthApiService>().resetPassword(
      token: token,
      newPassword: password,
    );
    if (!mounted) return;
    result.fold(
      (l) => _showMessage(l.toString()),
      (r) => setState(() => _isPasswordReset = true),
    );
    setState(() => _isLoading = false);
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }
}