import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sage/common/widgets/button/basic_app_button.dart';
import 'package:sage/core/configs/assets/app_images.dart';
import 'package:sage/core/configs/assets/app_vectors.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/presentation/auth/pages/signup_or_signin.dart';
import 'package:sage/presentation/choose_mode/bloc/theme_cubit.dart';

class ChooseModePage extends StatefulWidget {
  const ChooseModePage({super.key});

  @override
  State<ChooseModePage> createState() => _ChooseModePageState();
}

class _ChooseModePageState extends State<ChooseModePage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, selectedMode) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 50,
                ),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(
                      AppImages.chooseMadeBG,
                    ),
                  ),
                ),
              ),
              Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 50.0, horizontal: 40.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 70.0),
                      child: SvgPicture.asset(
                        AppVectors.logo,
                        height: 100,
                        width: 550,
                      ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Choose Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _modeOption(
                          context: context,
                          label: 'Dark Mode',
                          iconPath: AppVectors.moon,
                          mode: ThemeMode.dark,
                          selectedMode: selectedMode,
                        ),
                        _modeOption(
                          context: context,
                          label: 'Light Mode',
                          iconPath: AppVectors.sun,
                          mode: ThemeMode.light,
                          selectedMode: selectedMode,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    BasicAppButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                const SignupOrSignin(),
                          ),
                        );
                      },
                      title: "Continue",
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modeOption({
    required BuildContext context,
    required String label,
    required String iconPath,
    required ThemeMode mode,
    required ThemeMode selectedMode,
  }) {
    final isSelected = selectedMode == mode;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            context.read<ThemeCubit>().updateTheme(mode);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 82,
            width: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : AppColors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.darkGrey,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 87, sigmaY: 87),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    fit: BoxFit.none,
                    colorFilter: ColorFilter.mode(
                      isSelected ? AppColors.white : AppColors.greyTitle,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 17,
            color: isSelected ? AppColors.white : AppColors.grey,
          ),
        ),
      ],
    );
  }
}
