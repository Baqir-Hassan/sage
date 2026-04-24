import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sage/common/widgets/appbar/app_bar.dart';
import 'package:sage/common/widgets/button/basic_app_button.dart';
import 'package:sage/common/helpers/is_dark_mode.dart';
import 'package:sage/core/configs/assets/app_images.dart';
import 'package:sage/core/configs/assets/app_vectors.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/presentation/auth/pages/signup.dart';
import 'package:sage/presentation/auth/pages/singin.dart';

class SignupOrSignin extends StatelessWidget {
  const SignupOrSignin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BasicAppBar(),
          Align(
            alignment: Alignment.topRight,
            child: SvgPicture.asset(AppVectors.unionTop),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: SvgPicture.asset(AppVectors.unionBottom),
          ),
          Align(
            alignment: Alignment.bottomLeft,
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(AppVectors.logo),
                  const SizedBox(
                    height: 50,
                  ),
                  Text(
                    'Build Your Audio Study Library',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          context.isDarkMode ? AppColors.white : AppColors.dark,
                      fontSize: 29,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Create an account to upload notes, generate spoken lectures, and organize every subject into study collections.',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: context.isDarkMode
                          ? AppColors.greyTitle
                          : AppColors.grey,
                      fontSize: 19,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 35,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: BasicAppButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => SignupPage(),
                              ),
                            );
                          },
                          title: "Create Account",
                          textSize: 20,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(
                        width: 21,
                      ),
                      Expanded(
                        flex: 1,
                        child: TextButton(
                          child: Text(
                            "Log In",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: context.isDarkMode
                                  ? AppColors.white
                                  : AppColors.dark,
                              fontSize: 21,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => SigninPage(),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 100,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
