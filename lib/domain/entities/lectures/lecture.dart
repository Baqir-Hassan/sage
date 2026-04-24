class LectureEntity {
  final String title;
  final String summary;
  final num duration;
  final String? audioUrl;
  final String? imageUrl;
  final bool isSaved;
  final String lectureId;

  LectureEntity({
    required this.title,
    required this.summary,
    required this.duration,
    this.audioUrl,
    this.imageUrl,
    required this.isSaved,
    required this.lectureId,
  });
}
