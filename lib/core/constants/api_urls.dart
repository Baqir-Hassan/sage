class ApiUrls {
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.sageai.live');
  static const String apiV1 = '$baseUrl/api/v1';

  static const String signup = '$apiV1/auth/signup';
  static const String login = '$apiV1/auth/login';
  static const String me = '$apiV1/auth/me';
  static const String libraryHome = '$apiV1/library/home';
  static const String lectures = '$apiV1/lectures';
  static const String subjects = '$apiV1/subjects';
  static const String uploads = '$apiV1/uploads';
  static const String uploadLimits = '$uploads/limits';

  static String lectureTracks(String lectureId) =>
      '$lectures/$lectureId/tracks';
  static String lectureById(String lectureId) => '$lectures/$lectureId';
  static String subjectById(String subjectId) => '$subjects/$subjectId';
  static String lectureRegenerate(String lectureId) =>
      '$lectures/$lectureId/regenerate-content';
  static String uploadById(String documentId) => '$uploads/$documentId';
  static String uploadStatus(String documentId) => '$uploads/$documentId/status';
  static String subjectLectures(String subjectId) => '$subjects/$subjectId/lectures';
}
