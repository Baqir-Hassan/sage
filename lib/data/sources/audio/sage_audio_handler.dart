import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class SageAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  static const Duration _skipStep = Duration(seconds: 10);

  AudioPlayer get player => _player;

  SageAudioHandler() {
    _player.playbackEventStream.listen((_) {
      playbackState.add(_buildPlaybackState());
    }, onError: (Object _, StackTrace __) {
      playbackState.add(
        _buildPlaybackState(
          processingStateOverride: AudioProcessingState.error,
        ),
      );
    });

    _player.currentIndexStream.listen((index) {
      final queueItems = queue.value;
      if (index != null && index >= 0 && index < queueItems.length) {
        mediaItem.add(queueItems[index]);
      }
    });
  }

  Future<void> load({
    required String id,
    required String title,
    required String summary,
    required String? imageUrl,
    String? filePath,
    String? url,
    Map<String, String>? headers,
  }) async {
    final item = MediaItem(
      id: id,
      title: title,
      artist: summary,
      artUri:
          (imageUrl != null && imageUrl.isNotEmpty) ? Uri.tryParse(imageUrl) : null,
    );

    queue.add([item]);
    mediaItem.add(item);

    if (filePath != null && filePath.isNotEmpty) {
      await _player.setFilePath(filePath);
    } else if (url != null && url.isNotEmpty) {
      await _player.setUrl(url, headers: headers);
    } else {
      throw StateError('No audio source provided.');
    }

    playbackState.add(_buildPlaybackState());
  }

  PlaybackState _buildPlaybackState({
    AudioProcessingState? processingStateOverride,
  }) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToPrevious,
        MediaAction.skipToNext,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState:
          processingStateOverride ??
          const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => seek(_player.position + _skipStep);

  @override
  Future<void> skipToPrevious() {
    final target = _player.position - _skipStep;
    return seek(target < Duration.zero ? Duration.zero : target);
  }

  @override
  Future<void> onTaskRemoved() => stop();

  Future<void> dispose() => _player.dispose();
}
