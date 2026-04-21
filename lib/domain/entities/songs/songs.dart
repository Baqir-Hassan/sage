class SongEntity {
  final String title;
  final String artist;
  final num duration;
  final String? audioUrl;
  final String? imageUrl;
  final bool isFavorite;
  final String songId;

  SongEntity({
    required this.title,
    required this.artist,
    required this.duration,
    this.audioUrl,
    this.imageUrl,
    required this.isFavorite,
    required this.songId,
  });
}
