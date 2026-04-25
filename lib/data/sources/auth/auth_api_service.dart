import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage/core/constants/api_urls.dart';
import 'package:sage/core/constants/app_urls.dart';
import 'package:sage/data/sources/api/api_client.dart';
import 'package:sage/data/sources/auth/auth_token_provider.dart';
import 'package:sage/data/models/auth/create_user_req.dart';
import 'package:sage/data/models/auth/signin_user_req.dart';
import 'package:sage/data/models/auth/user.dart';
import 'package:sage/service_locator.dart';

abstract class AuthApiService {
  Future<Either> signup(CreateUserReq createUserReq);
  Future<Either> signin(SigninUserReq signinUserReq);
  Future<Either> getUser();
  Future<void> signout();
}

class AuthApiServiceImpl extends AuthApiService {
  // Kept in constructor to avoid churn in service locator wiring.
  // The actual network/token logic is centralized in ApiClient/AuthTokenProvider.
  // ignore: unused_field
  final http.Client _client;
  // ignore: unused_field
  final SharedPreferences _preferences;
  final ApiClient _apiClient = sl<ApiClient>();
  final AuthTokenProvider _tokenProvider = sl<AuthTokenProvider>();

  AuthApiServiceImpl({
    required http.Client client,
    required SharedPreferences preferences,
  })  : _client = client,
        _preferences = preferences;

  @override
  Future<Either> signup(CreateUserReq createUserReq) async {
    final result = await _apiClient.postJson(
      ApiUrls.signup,
      authenticated: false,
      body: {
        'full_name': createUserReq.fullName,
        'email': createUserReq.email,
        'password': createUserReq.password,
      },
    );

    return result.fold(
      (failure) => Left(failure),
      (body) async {
        if (body is Map<String, dynamic>) {
          final token = body['access_token'] as String?;
          if (token != null && token.isNotEmpty) {
            await _tokenProvider.setToken(token);
          }
        }
        return const Right('Signup was successful');
      },
    );
  }

  @override
  Future<Either> signin(SigninUserReq signinUserReq) async {
    final result = await _apiClient.postJson(
      ApiUrls.login,
      authenticated: false,
      body: {
        'email': signinUserReq.email,
        'password': signinUserReq.password,
      },
    );

    return result.fold(
      (failure) => Left(failure),
      (body) async {
        if (body is Map<String, dynamic>) {
          final token = body['access_token'] as String?;
          if (token != null && token.isNotEmpty) {
            await _tokenProvider.setToken(token);
          }
        }
        return const Right('Signin was successful');
      },
    );
  }

  @override
  Future<Either> getUser() async {
    if (_tokenProvider.getToken() == null) {
      return const Left('Please sign in first.');
    }

    final result = await _apiClient.getJson(ApiUrls.me, authenticated: true);
    return result.fold(
      (failure) => Left(failure),
      (body) {
        if (body is! Map<String, dynamic>) {
          return const Left('Unable to fetch profile.');
        }
        final userModel = UserModel.fromApiJson(body);
        if ((userModel.imageURL ?? '').isEmpty) {
          userModel.imageURL = AppUrls.defaultAvatar;
        }
        return Right(userModel.toEntity());
      },
    );
  }

  @override
  Future<void> signout() async {
    await _tokenProvider.clearToken();
  }
}
