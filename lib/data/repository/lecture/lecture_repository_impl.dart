import 'package:dartz/dartz.dart';
import 'package:sage/data/sources/lecture/lecture_api_service.dart';
import 'package:sage/domain/repository/lecture/lecture.dart';
import 'package:sage/service_locator.dart';

class LectureRepositoryImpl extends LectureRepository {
  @override
  Future<Either> getRecentLectures() async {
    return await sl<LectureApiService>().getRecentLectures();
  }

  @override
  Future<Either> getLectureLibrary() async {
    return await sl<LectureApiService>().getLectureLibrary();
  }

  @override
  Future<Either> toggleSavedLecture(String lectureId) async {
    return await sl<LectureApiService>().toggleSavedLecture(lectureId);
  }

  @override
  Future<bool> isSavedLecture(String lectureId) async {
    return await sl<LectureApiService>().isSavedLecture(lectureId);
  }

  @override
  Future<Either> getSavedLectures() async {
    return await sl<LectureApiService>().getSavedLectures();
  }
}
