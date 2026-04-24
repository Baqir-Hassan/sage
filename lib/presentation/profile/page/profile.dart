import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/common/helpers/is_dark_mode.dart';
import 'package:sage/common/widgets/appbar/app_bar.dart';
import 'package:sage/common/widgets/saved_lecture_button/saved_lecture_button.dart';
import 'package:sage/core/configs/assets/app_images.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';
import 'package:sage/presentation/lecture_player/pages/lecture_player.dart';
import 'package:sage/presentation/profile/bloc/profile_info_cubit.dart';
import 'package:sage/presentation/profile/bloc/profile_info_state.dart';
import 'package:sage/presentation/profile/bloc/saved_lectures_cubit.dart';
import 'package:sage/presentation/profile/bloc/saved_lectures_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasicAppBar(
        backgroundColor: AppColors.metalDark,
        title: Text('Study Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileInfo(context),
            const SizedBox(height: 30),
            _savedLectures(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _profileInfo(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileInfoCubit()..getUser(),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height / 3.8,
        ),
        decoration: BoxDecoration(
          color: context.isDarkMode ? AppColors.metalDark : AppColors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: BlocBuilder<ProfileInfoCubit, ProfileInfoState>(
          builder: (context, state) {
            if (state is ProfileInfoLoading) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is ProfileInfoLoaded) {
              final user = state.userEntity;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 84,
                      width: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(user.imageURL!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user.email ?? ''),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName ?? 'Sage User',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Unable to load your profile right now.'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _savedLectures() {
    return BlocProvider(
      create: (context) => SavedLecturesCubit()..getSavedLectures(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SAVED LECTURES',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            BlocBuilder<SavedLecturesCubit, SavedLecturesState>(
              builder: (context, state) {
                if (state is SavedLecturesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SavedLecturesLoaded) {
                  if (state.savedLectures.isEmpty) {
                    return const Text('No saved lectures yet.');
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final lecture = state.savedLectures[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  LecturePlayerPage(lectureEntity: lecture),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: _imageProviderFor(lecture),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lecture.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          lecture.summary,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_formatDuration(lecture.duration)),
                                const SizedBox(width: 12),
                                SavedLectureButton(
                                  lectureEntity: lecture,
                                  key: ValueKey(lecture.lectureId),
                                  function: () {
                                    context.read<SavedLecturesCubit>().removeLecture(index);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemCount: state.savedLectures.length,
                  );
                }

                return const Text('Unable to load saved lectures.');
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _imageProviderFor(LectureEntity lecture) {
    final imageUrl = lecture.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }
    return const AssetImage(AppImages.homeArtwork);
  }

  String _formatDuration(num durationInSeconds) {
    final duration = Duration(seconds: durationInSeconds.round());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
