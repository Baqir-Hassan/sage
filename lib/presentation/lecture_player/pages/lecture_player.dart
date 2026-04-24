import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/common/helpers/is_dark_mode.dart';
import 'package:sage/common/widgets/appbar/app_bar.dart';
import 'package:sage/common/widgets/saved_lecture_button/saved_lecture_button.dart';
import 'package:sage/core/configs/assets/app_images.dart';
import 'package:sage/core/configs/theme/app_color.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';
import 'package:sage/presentation/lecture_player/bloc/lecture_player_cubit.dart';
import 'package:sage/presentation/lecture_player/bloc/lecture_player_state.dart';

class LecturePlayerPage extends StatelessWidget {
  final LectureEntity lectureEntity;

  const LecturePlayerPage({
    super.key,
    required this.lectureEntity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppBar(
        title: const Text(
          'Lecture Playback',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        action: IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.more_vert_rounded,
            color: context.isDarkMode
                ? const Color(0xff959595)
                : const Color(0xff555555),
          ),
        ),
      ),
      body: BlocProvider(
        create: (_) => LecturePlayerCubit()
          ..loadLectureAudio(
            url: lectureEntity.audioUrl ?? '',
            title: lectureEntity.title,
            summary: lectureEntity.summary,
            imageUrl: lectureEntity.imageUrl,
          ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              children: [
                _coverArtwork(context),
                const SizedBox(height: 10),
                _lectureDetail(),
                const SizedBox(height: 30),
                _playbackControls(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverArtwork(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: _imageProviderFor(lectureEntity),
        ),
      ),
    );
  }

  Widget _lectureDetail() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lectureEntity.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              lectureEntity.summary,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            const Text(
              'AI narrated lesson',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SavedLectureButton(
          sizeIcons: 30,
          lectureEntity: lectureEntity,
        ),
      ],
    );
  }

  Widget _playbackControls(BuildContext context) {
    return BlocBuilder<LecturePlayerCubit, LecturePlayerState>(
      builder: (BuildContext context, LecturePlayerState state) {
        if (state is LecturePlayerLoading) {
          return const CircularProgressIndicator();
        }

        if (state is LecturePlayerFailure) {
          return const Text(
            'Audio is not ready for this lecture yet.',
            textAlign: TextAlign.center,
          );
        }

        if (state is LecturePlayerLoaded) {
          return Column(
            children: [
              Slider(
                value: context
                    .read<LecturePlayerCubit>()
                    .playbackPosition
                    .inSeconds
                    .toDouble(),
                min: 0.0,
                max: context
                    .read<LecturePlayerCubit>()
                    .playbackDuration
                    .inSeconds
                    .toDouble(),
                onChanged: (value) {},
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(
                        context.read<LecturePlayerCubit>().playbackPosition),
                  ),
                  Text(
                    _formatDuration(
                        context.read<LecturePlayerCubit>().playbackDuration),
                  )
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  context.read<LecturePlayerCubit>().togglePlayback();
                },
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: Icon(
                    context.read<LecturePlayerCubit>().audioPlayer.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: context.isDarkMode
                        ? AppColors.white
                        : AppColors.darkGrey,
                  ),
                ),
              ),
            ],
          );
        }

        return Container();
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ImageProvider _imageProviderFor(LectureEntity lecture) {
    final imageUrl = lecture.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }
    return const AssetImage(AppImages.homeArtwork);
  }
}
