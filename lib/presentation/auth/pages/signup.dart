import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sage/common/widgets/appbar/app_bar.dart';
import 'package:sage/common/widgets/button/basic_app_button.dart';
import 'package:sage/core/configs/assets/app_vectors.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/data/models/auth/create_user_req.dart';
import 'package:sage/domain/usecase/auth/signup.dart';
import 'package:sage/data/sources/auth/auth_api_service.dart';
import 'package:sage/presentation/auth/pages/singin.dart';
import 'package:sage/presentation/auth/pages/verify_email.dart';
import 'package:sage/service_locator.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLoading = false;
  bool _showVerificationState = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
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
        bottomNavigationBar: _signinText(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 50,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _registerText(),
              const SizedBox(height: 25),
              _supportText(),
              const SizedBox(height: 25),
              _fullNameField(context),
              const SizedBox(height: 20),
              _emailField(context),
              const SizedBox(height: 20),
              _passwordField(context),
              const SizedBox(height: 30),
              BasicAppButton(
                onPressed: _isLoading ? null : _createAccount,
                title: _isLoading ? "Creating..." : "Create Account",
                textSize: 22,
                weight: FontWeight.w500,
              ),
              if (_showVerificationState) ...[
                const SizedBox(height: 16),
                const Text(
                  "Please check your inbox for a verification email. If you don't see it, check your spam/junk folder.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : _resendVerification,
                  child: const Text("Resend verification email"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => VerifyEmailPage(
                          prefilledEmail: _email.text.trim(),
                        ),
                      ),
                    );
                  },
                  child: const Text("Already have token? Verify now"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _registerText() {
    return const Text(
      'Register',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _supportText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "If You Need Any Support ",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            "Click here",
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

  Widget _fullNameField(BuildContext context) {
    return TextField(
      controller: _fullName,
      decoration: const InputDecoration(
        hintText: "Full Name",
      ).applyDefaults(
        Theme.of(context).inputDecorationTheme,
      ),
    );
  }

  Widget _passwordField(BuildContext context) {
    return TextField(
      controller: _password,
      obscureText: true,
      decoration: const InputDecoration(
        hintText: "Create Password",
      ).applyDefaults(
        Theme.of(context).inputDecorationTheme,
      ),
    );
  }

  Widget _emailField(BuildContext context) {
    return TextField(
      controller: _email,
      decoration: const InputDecoration(
        hintText: "Enter Email",
      ).applyDefaults(
        Theme.of(context).inputDecorationTheme,
      ),
    );
  }

  Widget _signinText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 40,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Do You Have An Account?",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const SigninPage(),
                ),
              );
            },
            child: const Text(
              "Sign In",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAccount() async {
    setState(() {
      _isLoading = true;
    });
    final result = await sl<SignupUseCase>().call(
      params: CreateUserReq(
        email: _email.text.trim(),
        fullName: _fullName.text.trim(),
        password: _password.text,
      ),
    );

    if (!mounted) return;
    result.fold(
      (l) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (r) {
        setState(() {
          _showVerificationState = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(r.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _resendVerification() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter your email first."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final result = await sl<AuthApiService>().resendVerification(email);
    if (!mounted) return;
    result.fold(
      (l) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.toString()), behavior: SnackBarBehavior.floating),
      ),
      (r) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.toString()), behavior: SnackBarBehavior.floating),
      ),
    );
    setState(() {
      _isLoading = false;
    });
  }
}
