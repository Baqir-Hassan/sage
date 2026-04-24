import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/common/bloc/saved_lecture_button/saved_lecture_button_cubit.dart';
import 'package:sage/common/bloc/saved_lecture_button/saved_lecture_button_state.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';

class SavedLectureButton extends StatelessWidget {
  final LectureEntity lectureEntity;
  final double sizeIcons;
  final Function? function;

  const SavedLectureButton({
    super.key,
    required this.lectureEntity,
    this.sizeIcons = 25,
    this.function,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SavedLectureButtonCubit(),
      child: BlocBuilder<SavedLectureButtonCubit, SavedLectureButtonState>(
        builder: (context, state) {
          if (state is SavedLectureButtonInitial) {
            return IconButton(
              onPressed: () async {
                await context.read<SavedLectureButtonCubit>().savedLectureButtonUpdated(
                      lectureEntity.lectureId,
                    );

                if (function != null) {
                  function!();
                }
              },
              icon: Icon(
                lectureEntity.isSaved
                    ? Icons.favorite
                    : Icons.favorite_outline_outlined,
                size: sizeIcons,
                color: AppColors.darkGrey,
              ),
            );
          }

          if (state is SavedLectureButtonUpdated) {
            return IconButton(
              onPressed: () {
                context.read<SavedLectureButtonCubit>().savedLectureButtonUpdated(
                      lectureEntity.lectureId,
                    );
              },
              icon: Icon(
                state.isSaved
                    ? Icons.favorite
                    : Icons.favorite_outline_outlined,
                size: sizeIcons,
                color: AppColors.darkGrey,
              ),
            );
          }

          return Container();
        },
      ),
    );
  }
}
