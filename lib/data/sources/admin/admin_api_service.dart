import 'package:dartz/dartz.dart';
import 'package:sage/core/constants/api_urls.dart';
import 'package:sage/data/sources/api/api_client.dart';
import 'package:sage/data/sources/auth/auth_token_provider.dart';
import 'package:sage/service_locator.dart';

abstract class AdminApiService {
  Future<Either<String, dynamic>> getUserLimits(String userId);
  Future<Either<String, dynamic>> getUserLimitsByEmail(String email);
  Future<Either<String, dynamic>> updateUserLimits({
    required String userId,
    int? dailyNewLectureLimit,
    int? dailyRegenerationLimit,
  });
}

class AdminApiServiceImpl extends AdminApiService {
  final ApiClient _apiClient = sl<ApiClient>();
  final AuthTokenProvider _tokenProvider = sl<AuthTokenProvider>();

  @override
  Future<Either<String, dynamic>> getUserLimits(String userId) async {
    if (_tokenProvider.getToken() == null) {
      return const Left('Please sign in first.');
    }

    return _apiClient.getJson(ApiUrls.adminUserLimits(userId));
  }

  @override
  Future<Either<String, dynamic>> getUserLimitsByEmail(String email) async {
    if (_tokenProvider.getToken() == null) {
      return const Left('Please sign in first.');
    }

    return _apiClient.getJson(ApiUrls.adminUserLimitsByEmail(email));
  }

  @override
  Future<Either<String, dynamic>> updateUserLimits({
    required String userId,
    int? dailyNewLectureLimit,
    int? dailyRegenerationLimit,
  }) async {
    if (_tokenProvider.getToken() == null) {
      return const Left('Please sign in first.');
    }

    return _apiClient.patchJson(
      ApiUrls.adminUserLimits(userId),
      body: {
        'daily_new_lecture_limit': dailyNewLectureLimit,
        'daily_regeneration_limit': dailyRegenerationLimit,
      },
    );
  }
}
