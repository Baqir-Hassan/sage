import 'package:flutter/material.dart';
import 'package:sage/core/configs/assets/app_images.dart';
import 'package:sage/domain/usecase/auth/get_user.dart';
import 'package:sage/presentation/home/pages/home.dart';
import 'package:sage/presentation/intro/pages/get_started.dart';
import 'package:sage/service_locator.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    redirect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Image(
          image: AssetImage(AppImages.logo),
          width: 140,
          height: 140,
        ),
      ),
    );
  }

  Future<void> redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final userResult = await sl<GetUserUseCase>().call();
      final isAuthenticated = userResult.isRight();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              isAuthenticated ? const HomePage() : const GetStartedPage(),
        ),
      );
    }
  }
}
