import 'package:sage/domain/entities/lectures/lecture.dart';

class LectureModel {
  String? title;
  String? summary;
  num? duration;
  String? audioUrl;
  String? imageUrl;
  bool? isSaved;
  String? lectureId;

  LectureModel.fromJson(Map<String, dynamic> data) {
    title = data['title'];
    summary = data['summary'];
    duration = data['duration'];
    audioUrl = data['audioUrl'];
    imageUrl = data['imageUrl'];
    isSaved = data['isSaved'];
    lectureId = data['lectureId'];
  }
}

extension LectureModelX on LectureModel {
  LectureEntity toEntity() {
    return LectureEntity(
      title: title!,
      summary: summary!,
      duration: duration!,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      isSaved: isSaved!,
      lectureId: lectureId!,
    );
  }
}
