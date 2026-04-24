abstract class SavedLectureButtonState {}

class SavedLectureButtonInitial extends SavedLectureButtonState {}

class SavedLectureButtonUpdated extends SavedLectureButtonState {
  final bool isSaved;

  SavedLectureButtonUpdated({
    required this.isSaved,
  });
}
