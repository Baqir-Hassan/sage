import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/common/helpers/is_dark_mode.dart';
import 'package:sage/common/widgets/appbar/app_bar.dart';
import 'package:sage/common/widgets/saved_lecture_button/saved_lecture_button.dart';
import 'package:sage/core/configs/assets/app_images.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';
import 'package:sage/presentation/profile/bloc/saved_lectures_cubit.dart';
import 'package:sage/presentation/profile/bloc/saved_lectures_state.dart';
import 'package:sage/presentation/profile/bloc/profile_info_cubit.dart';
import 'package:sage/presentation/profile/bloc/profile_info_state.dart';
import 'package:sage/presentation/lecture_player/pages/lecture_player.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasicAppBar(
        backgroundColor: AppColors.metalDark,
        title: Text('Study Profile'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _profileInfo(context),
          const SizedBox(height: 30),
          _savedLectures(),
        ],
      ),
    );
  }

  Widget _profileInfo(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileInfoCubit()..getUser(),
      child: Container(
        height: MediaQuery.of(context).size.height / 3.5,
        decoration: BoxDecoration(
          color: context.isDarkMode ? AppColors.metalDark : AppColors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
        ),
        child: BlocBuilder<ProfileInfoCubit, ProfileInfoState>(
          builder: (context, state) {
            if (state is ProfileInfoLoading) {
              return Container(
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            }

            if (state is ProfileInfoLoaded) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(state.userEntity.imageURL!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      state.userEntity.email!,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      state.userEntity.fullName!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              );
            }

            if (state is ProfileInfoFailure) {
              return const Center(
                child: Text('Please try again'),
              );
            }

            return Container();
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
            const Text('SAVED LECTURES'),
            const SizedBox(height: 20),
            BlocBuilder<SavedLecturesCubit, SavedLecturesState>(
                builder: (context, state) {
              if (state is SavedLecturesLoading) {
                return const CircularProgressIndicator();
              }

              if (state is SavedLecturesLoaded) {
                return ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    LecturePlayerPage(
                                        lectureEntity:
                                            state.savedLectures[index])));
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // lecture artwork
                          Row(
                            children: [
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: _imageProviderFor(
                                      state.savedLectures[index],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.savedLectures[index].title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    state.savedLectures[index].summary,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                _formatDuration(
                                  state.savedLectures[index].duration,
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              SavedLectureButton(
                                lectureEntity: state.savedLectures[index],
                                key: UniqueKey(),
                                function: () {
                                  context
                                      .read<SavedLecturesCubit>()
                                      .removeLecture(index);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, state) =>
                      const SizedBox(height: 20),
                  itemCount: state.savedLectures.length,
                );
              }

              if (state is SavedLecturesFailure) {
                return const Text('Please try again');
              }

              return Container();
            })
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
