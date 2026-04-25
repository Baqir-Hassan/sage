import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sage/common/widgets/button/basic_app_button.dart';
import 'package:sage/core/configs/assets/app_images.dart';
import 'package:sage/core/configs/assets/app_vectors.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/presentation/choose_mode/pages/choose_mode.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  AppImages.introBG,
                ),
              ),
            ),
            // child:
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 100.0, horizontal: 40.0),
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
                  'Turn Notes Into Audio Lectures',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                const Text(
                  'Upload your PDFs and slide decks, generate narrated lessons, and study from a library that feels as polished as your favorite listening app.',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyTitle,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 30,
                ),
                BasicAppButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const ChooseModePage(),
                      ),
                    );
                  },
                  title: "Start Learning",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}