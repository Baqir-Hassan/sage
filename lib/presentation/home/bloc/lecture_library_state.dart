import 'package:sage/domain/entities/lectures/lecture.dart';

abstract class LectureLibraryState {}

class LectureLibraryLoading extends LectureLibraryState {}

class LectureLibraryLoaded extends LectureLibraryState {
  final List<LectureEntity> lectures;
  LectureLibraryLoaded({required this.lectures});
}

class LectureLibraryLoadFailure extends LectureLibraryState {}
