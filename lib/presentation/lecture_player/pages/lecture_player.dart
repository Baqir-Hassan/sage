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
import 'package:sage/presentation/shutter_widget/shutter_widget.dart';

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
            lectureId: lectureEntity.lectureId,
            url: lectureEntity.audioUrl ?? '',
            title: lectureEntity.title,
            summary: lectureEntity.summary,
            localAudioPath: lectureEntity.localAudioPath,
            imageUrl: lectureEntity.imageUrl,
          ),
        child: BlocBuilder<LecturePlayerCubit, LecturePlayerState>(
          builder: (context, state) {
            if (state is LecturePlayerLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is LecturePlayerFailure) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'Audio is not ready for this lecture yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final cubit = context.read<LecturePlayerCubit>();
            final duration = cubit.playbackDuration == Duration.zero
                ? Duration(seconds: lectureEntity.duration.toInt())
                : cubit.playbackDuration;
            final durationMs = duration.inMilliseconds;
            final progress = durationMs <= 0
                ? 0.0
                : (cubit.playbackPosition.inMilliseconds / durationMs).clamp(0.0, 1.0);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    _coverArtwork(context),
                    const SizedBox(height: 18),
                    _lectureDetail(),
                    const SizedBox(height: 28),
                    ShutterWidget(
                      title: lectureEntity.title,
                      subtitle: lectureEntity.summary,
                      progress: progress,
                      elapsed: cubit.playbackPosition,
                      total: duration,
                      isPlaying: cubit.audioPlayer.playing,
                      imageUrl: lectureEntity.imageUrl,
                      onTogglePlayback: cubit.togglePlayback,
                      onSeek: cubit.seekToFraction,
                    ),
                  ],
                ),
              ),
            );
          },
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

  ImageProvider _imageProviderFor(LectureEntity lecture) {
    final imageUrl = lecture.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }
    return const AssetImage(AppImages.homeArtwork);
  }
}
