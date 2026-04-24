import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/common/helpers/is_dark_mode.dart';
import 'package:sage/common/widgets/saved_lecture_button/saved_lecture_button.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';
import 'package:sage/presentation/home/bloc/lecture_library_cubit.dart';
import 'package:sage/presentation/home/bloc/lecture_library_state.dart';
import 'package:sage/presentation/lecture/pages/lecture_detail.dart';

class LectureLibrary extends StatelessWidget {
  const LectureLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LectureLibraryCubit()..getLectureLibrary(),
      child: SizedBox(
        child: BlocBuilder<LectureLibraryCubit, LectureLibraryState>(
          builder: (context, state) {
            if (state is LectureLibraryLoading) {
              return Container(
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator());
            }

            if (state is LectureLibraryLoaded) {
              return _lectureLibrary(state.lectures);
            }

            return Container();
          },
        ),
      ),
    );
  }

  Widget _lectureLibrary(List<LectureEntity> lectures) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Lecture Library",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                "Browse All",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _lectureList(lectures),
        ],
      ),
    );
  }

  Widget _lectureList(List<LectureEntity> lectures) {
    return ListView.separated(
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => LectureDetailPage(
                  lecture: lectures[index],
                ),
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
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.isDarkMode
                            ? AppColors.darkGrey
                            : AppColors.greyWhite,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: context.isDarkMode
                            ? AppColors.white
                            : AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lectures[index].title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            lectures[index].summary,
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Text(_formatDuration(lectures[index].duration)),
                  const SizedBox(
                    width: 20,
                  ),
                  SavedLectureButton(
                    lectureEntity: lectures[index],
                  ),
                ],
              ),
            ],
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(
        height: 25,
      ),
      itemCount: lectures.length,
    );
  }

  String _formatDuration(num durationInSeconds) {
    final duration = Duration(seconds: durationInSeconds.round());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
