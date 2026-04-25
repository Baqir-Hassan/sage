import 'package:dartz/dartz.dart';
import 'package:sage/data/models/auth/create_user_req.dart';
import 'package:sage/data/models/auth/signin_user_req.dart';
import 'package:sage/data/sources/auth/auth_api_service.dart';
import 'package:sage/domain/repository/auth/auth.dart';
import 'package:sage/service_locator.dart';

class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<Either> signin(SigninUserReq signinUserReq) async {
    return await sl<AuthApiService>().signin(signinUserReq);
  }

  @override
  Future<Either> signup(CreateUserReq createUserReq) async {
    return await sl<AuthApiService>().signup(createUserReq);
  }

  @override
  Future<Either> getUser() async {
    return await sl<AuthApiService>().getUser();
  }

  @override
  Future<void> signout() async {
    await sl<AuthApiService>().signout();
  }
}
