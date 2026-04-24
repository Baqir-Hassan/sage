import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/common/helpers/is_dark_mode.dart';
import 'package:sage/core/configs/assets/app_images.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';
import 'package:sage/presentation/home/bloc/recent_lectures_cubit.dart';
import 'package:sage/presentation/home/bloc/recent_lectures_state.dart';
import 'package:sage/presentation/lecture/pages/lecture_detail.dart';

class RecentLectures extends StatelessWidget {
  const RecentLectures({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecentLecturesCubit()..getRecentLectures(),
      child: SizedBox(
        height: 330,
        child: BlocBuilder<RecentLecturesCubit, RecentLecturesState>(
          builder: (context, state) {
            if (state is RecentLecturesLoading) {
              return Container(
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator());
            }

            if (state is RecentLecturesLoaded) {
              return _lectureCards(state.lectures);
            }

            return Container();
          },
        ),
      ),
    );
  }

  Widget _lectureCards(List<LectureEntity> lectures) {
    return ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: GestureDetector(
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
              child: SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: _imageProviderFor(lectures[index]),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          height: 30,
                          width: 30,
                          transform: Matrix4.translationValues(-10, 10, 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.isDarkMode
                                ? AppColors.darkGrey
                                : const Color(0xffE6E6E6),
                          ),
                          child: Icon(
                            Icons.headphones_rounded,
                            color: context.isDarkMode
                                ? const Color(0xff959595)
                                : const Color(0xff555555),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lectures[index].title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.fade,
                              softWrap: true,
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(
                              lectures[index].summary,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.fade,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(
              width: 1,
            ),
        itemCount: lectures.length);
  }

  ImageProvider _imageProviderFor(LectureEntity lecture) {
    final imageUrl = lecture.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }
    return const AssetImage(AppImages.homeArtwork);
  }
}
