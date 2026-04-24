import 'package:dartz/dartz.dart';

abstract class LectureRepository {
  Future<Either> getRecentLectures();
  Future<Either> getLectureLibrary();
  Future<Either> toggleSavedLecture(String lectureId);
  Future<bool> isSavedLecture(String lectureId);
  Future<Either> getSavedLectures();
}
