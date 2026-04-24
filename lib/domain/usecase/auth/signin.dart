import 'package:dartz/dartz.dart';
import 'package:sage/core/usecase/usecase.dart';
import 'package:sage/data/models/auth/signin_user_req.dart';
import 'package:sage/domain/repository/auth/auth.dart';
import 'package:sage/service_locator.dart';

class SigninUseCase implements UseCase<Either, SigninUserReq> {
  @override
  Future<Either> call({SigninUserReq? params}) async {
    return sl<AuthRepository>().signin(params!);
  }
}
