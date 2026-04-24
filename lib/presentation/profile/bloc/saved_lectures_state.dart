import 'package:sage/domain/entities/lectures/lecture.dart';

abstract class SavedLecturesState {}

class SavedLecturesLoading extends SavedLecturesState {}

class SavedLecturesLoaded extends SavedLecturesState {
  final List<LectureEntity> savedLectures;

  SavedLecturesLoaded({
    required this.savedLectures,
  });
}

class SavedLecturesFailure extends SavedLecturesState {}
