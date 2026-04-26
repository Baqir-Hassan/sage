import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sage/common/widgets/appbar/app_bar.dart';
import 'package:sage/common/widgets/button/basic_app_button.dart';
import 'package:sage/core/configs/assets/app_vectors.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/data/models/auth/signin_user_req.dart';
import 'package:sage/data/sources/auth/auth_api_service.dart';
import 'package:sage/domain/usecase/auth/signin.dart';
import 'package:sage/presentation/auth/pages/signup.dart';
import 'package:sage/presentation/home/pages/home.dart';
import 'package:sage/service_locator.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLoading = false;
  bool _showResendVerification = false;

  @override
  void dispose() {
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
        bottomNavigationBar: _registerText(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 50,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _signinText(),
              const SizedBox(height: 25),
              _supportText(),
              const SizedBox(height: 25),
              _usernameOrEmailField(context),
              const SizedBox(height: 20),
              _passwordField(context),
              const SizedBox(height: 16),
              _recoveryPasswordText(),
              const SizedBox(height: 16),
              BasicAppButton(
                title: 'Sign in',
                onPressed: _isLoading ? null : _signin,
                textSize: 22,
                weight: FontWeight.w500,
              ),
              if (_showResendVerification) ...[
                const SizedBox(height: 16),
                const Text(
                  "Please verify your email before signing in. If you don't see it, check your spam/junk folder.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading ? null : _resendVerification,
                  child: const Text("Resend verification email"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _signinText() {
    return const Text(
      'Sign In',
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

  Widget _usernameOrEmailField(BuildContext context) {
    return TextField(
      controller: _email,
      decoration: const InputDecoration(
        hintText: "Enter Username Or Email",
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
        hintText: "Password",
      ).applyDefaults(
        Theme.of(context).inputDecorationTheme,
      ),
    );
  }

  Widget _recoveryPasswordText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {},
          child: const Text(
            "Recovery Password",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _registerText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 40,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Not A Member ? ",
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
                  builder: (BuildContext context) => const SignupPage(),
                ),
              );
            },
            child: const Text(
              "Register Now",
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

  Future<void> _signin() async {
    setState(() {
      _isLoading = true;
      _showResendVerification = false;
    });
    final result = await sl<SigninUseCase>().call(
      params: SigninUserReq(
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
    if (!mounted) return;

    result.fold(
      (l) {
        final error = l.toString();
        setState(() {
          _showResendVerification = error.toLowerCase().contains("verify your email");
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
        );
      },
      (_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const HomePage(),
          ),
          (route) => false,
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
