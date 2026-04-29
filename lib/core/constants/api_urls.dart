class ApiUrls {
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.sageai.live');
  static const String apiV1 = '$baseUrl/api/v1';

  static const String signup = '$apiV1/auth/signup';
  static const String login = '$apiV1/auth/login';
  static const String me = '$apiV1/auth/me';
  static const String verifyEmail = '$apiV1/auth/verify-email';
  static const String resendVerification = '$apiV1/auth/resend-verification';
  static const String forgotPassword = '$apiV1/auth/forgot-password';
  static const String resetPassword = '$apiV1/auth/reset-password';
  static const String libraryHome = '$apiV1/library/home';
  static const String lectures = '$apiV1/lectures';
  static const String subjects = '$apiV1/subjects';
  static const String uploads = '$apiV1/uploads';
  static const String uploadLimits = '$uploads/limits';
  static const String admin = '$apiV1/admin';

  static String lectureTracks(String lectureId) =>
      '$lectures/$lectureId/tracks';
  static String lectureById(String lectureId) => '$lectures/$lectureId';
  static String subjectById(String subjectId) => '$subjects/$subjectId';
  static String lectureRegenerate(String lectureId) =>
      '$lectures/$lectureId/regenerate-content';
  static String uploadById(String documentId) => '$uploads/$documentId';
  static String uploadStatus(String documentId) => '$uploads/$documentId/status';
  static String subjectLectures(String subjectId) => '$subjects/$subjectId/lectures';
  static String adminUserLimits(String userId) => '$admin/users/$userId/limits';
  static String adminUserLimitsByEmail(String email) =>
      '$admin/users/limits/by-email?email=${Uri.encodeComponent(email)}';
  static String adminUserSearchByEmailPrefix(String emailPrefix) =>
      '$admin/users/search?email_prefix=${Uri.encodeComponent(emailPrefix)}';
}
