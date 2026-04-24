import 'package:sage/domain/entities/lectures/lecture.dart';

abstract class RecentLecturesState {}

class RecentLecturesLoading extends RecentLecturesState {}

class RecentLecturesLoaded extends RecentLecturesState {
  final List<LectureEntity> lectures;
  RecentLecturesLoaded({required this.lectures});
}

class RecentLecturesLoadFailure extends RecentLecturesState {}
