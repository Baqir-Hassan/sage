import 'package:flutter/material.dart';
import 'package:spotify_with_flutter/common/widgets/appbar/app_bar.dart';
import 'package:spotify_with_flutter/common/widgets/button/basic_app_button.dart';
import 'package:spotify_with_flutter/core/configs/assets/app_images.dart';
import 'package:spotify_with_flutter/core/configs/theme/app_color.dart';
import 'package:spotify_with_flutter/data/sources/song/song_api_service.dart';
import 'package:spotify_with_flutter/domain/entities/songs/songs.dart';
import 'package:spotify_with_flutter/presentation/song_player.dart/pages/song_player.dart';
import 'package:spotify_with_flutter/service_locator.dart';

class LectureDetailPage extends StatefulWidget {
  final SongEntity lecture;

  const LectureDetailPage({
    super.key,
    required this.lecture,
  });

  @override
  State<LectureDetailPage> createState() => _LectureDetailPageState();
}

class _LectureDetailPageState extends State<LectureDetailPage> {
  bool _isLoading = true;
  bool _isRegenerating = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _tracks = const [];

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasicAppBar(
        title: Text('Lecture Details'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTracks,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            _heroCard(),
            const SizedBox(height: 20),
            BasicAppButton(
              onPressed: _isRegenerating ? () {} : _regenerateLecture,
              title: _isRegenerating ? 'Regenerating...' : 'Regenerate Lecture',
              textSize: 18,
              weight: FontWeight.w600,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              _messageCard(
                title: 'Unable to load sections',
                subtitle: _errorMessage!,
                actionLabel: 'Try Again',
                onPressed: _loadTracks,
              )
            else if (_tracks.isEmpty)
              _messageCard(
                title: 'No sections yet',
                subtitle:
                    'This lecture does not have playable sections yet. Try regenerating it once.',
                actionLabel: 'Refresh',
                onPressed: _loadTracks,
              )
            else
              ..._tracks.map(_trackTile),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1DD75F),
            Color(0xFF0E8F4E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generated Lecture',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.lecture.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.lecture.artist,
                  maxLines: 3,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              AppImages.homeArtist,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required Future<void> Function() onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.greyWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () => onPressed(),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _trackTile(Map<String, dynamic> track) {
    final title = track['title'] as String? ?? 'Untitled Section';
    final duration = (track['duration_seconds'] as num?)?.round() ?? 0;
    final status = track['status'] as String? ?? 'unknown';
    final mediaUrl = track['media_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.greyWhite,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: IconButton(
              onPressed: mediaUrl == null || mediaUrl.isEmpty
                  ? null
                  : () => _openTrackPlayer(track),
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    color: AppColors.darkGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status == 'completed'
                      ? 'Ready to play'
                      : 'Status: $status',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDuration(duration),
            style: const TextStyle(
              color: AppColors.darkGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        await sl<SongApiService>().getLectureTracks(widget.lecture.songId);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.toString();
        });
      },
      (data) {
        setState(() {
          _isLoading = false;
          _tracks = (data as List<dynamic>).cast<Map<String, dynamic>>();
        });
      },
    );
  }

  Future<void> _regenerateLecture() async {
    setState(() {
      _isRegenerating = true;
    });

    final result =
        await sl<SongApiService>().regenerateLecture(widget.lecture.songId);

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.toString())),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lecture regenerated successfully.')),
        );
      },
    );

    setState(() {
      _isRegenerating = false;
    });
    await _loadTracks();
  }

  void _openTrackPlayer(Map<String, dynamic> track) {
    final mediaUrl = track['media_url'] as String?;
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return;
    }

    final duration = (track['duration_seconds'] as num?)?.round() ?? 0;
    final sectionTitle = track['title'] as String? ?? 'Lecture Section';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongPlayerPage(
          songEntity: SongEntity(
            title: sectionTitle,
            artist: widget.lecture.title,
            duration: duration,
            audioUrl: mediaUrl,
            imageUrl: widget.lecture.imageUrl,
            isFavorite: widget.lecture.isFavorite,
            songId: track['id'] as String? ?? widget.lecture.songId,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
