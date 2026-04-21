import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:spotify_with_flutter/common/helpers/is_dark_mode.dart';
import 'package:spotify_with_flutter/core/configs/assets/app_images.dart';
import 'package:spotify_with_flutter/core/configs/assets/app_vectors.dart';
import 'package:spotify_with_flutter/core/configs/theme/app_color.dart';
import 'package:spotify_with_flutter/presentation/home/widgets/news_songs.dart';
import 'package:spotify_with_flutter/presentation/home/widgets/play_list.dart';
import 'package:spotify_with_flutter/presentation/home/widgets/subjects_tab.dart';
import 'package:spotify_with_flutter/presentation/home/widgets/uploads_tab.dart';
import 'package:spotify_with_flutter/presentation/profile/page/profile.dart';
import 'package:spotify_with_flutter/presentation/upload/pages/upload_notes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBarArtist(context),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _homeTopCard(),
            _uploadBanner(context),
            _tabs(),
            const SizedBox(height: 10),
            SizedBox(
              height: 340,
              child: TabBarView(
                controller: _tabController,
                children: [
                  const NewsSongs(),
                  const SubjectsTab(),
                  const UploadsTab(),
                  const PlayList(),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const PlayList(),
          ],
        ),
      ),
    );
  }

  AppBar _appBarArtist(BuildContext context) {
    return AppBar(
      title: SvgPicture.asset(
        AppVectors.logo,
        height: 40,
        width: 40,
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const ProfilePage(),
              ),
            );
          },
          icon: const Icon(Icons.person_outline_rounded),
        ),
      ],
      leading: IconButton(
        onPressed: () {
          // Navigator.pop(context);
        },
        icon: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? AppColors.white.withOpacity(0.03)
                : AppColors.dark.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.search_rounded,
            size: 30,
            color: context.isDarkMode ? AppColors.white : AppColors.dark,
          ),
        ),
      ),
    );
  }

  Widget _homeTopCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Featured Course',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Parallel Computing',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 25,
                              ),
                            ),
                            Text(
                              'Freshly generated lecture series',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: SvgPicture.asset(AppVectors.unionHomeArtistTop),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Image.asset(
                    AppImages.homeArtist,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: TabBar(
        labelColor: context.isDarkMode ? AppColors.white : AppColors.dark,
        indicatorColor: AppColors.primary,
        controller: _tabController,
        tabs: const [
          Text(
            'Recent',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Subjects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Uploads',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Saved',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: context.isDarkMode
              ? AppColors.darkGrey.withOpacity(0.35)
              : AppColors.greyWhite,
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload new notes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Drop in a PDF or slide deck and generate a narrated lecture in minutes.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => const UploadNotesPage(),
                  ),
                );
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
