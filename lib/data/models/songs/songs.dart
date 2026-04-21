import 'package:spotify_with_flutter/domain/entities/songs/songs.dart';

class SongModel {
  String? title;
  String? artist;
  num? duration;
  String? audioUrl;
  String? imageUrl;
  bool? isFavorite;
  String? songId;

  SongModel.fromJson(Map<String, dynamic> data) {
    title = data['title'];
    artist = data['artist'];
    duration = data['duration'];
    audioUrl = data['audioUrl'];
    imageUrl = data['imageUrl'];
    isFavorite = data['isFavorite'];
    songId = data['songId'];
  }
}

extension SongModelX on SongModel {
  SongEntity toEntity() {
    return SongEntity(
      title: title!,
      artist: artist!,
      duration: duration!,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      isFavorite: isFavorite!,
      songId: songId!,
    );
  }
}
