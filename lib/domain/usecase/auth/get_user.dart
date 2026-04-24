import 'package:dartz/dartz.dart';
import 'package:sage/core/usecase/usecase.dart';
import 'package:sage/domain/repository/auth/auth.dart';
import 'package:sage/service_locator.dart';

class GetUserUseCase implements UseCase<Either, dynamic> {
  @override
  Future<Either> call({params}) async {
    return await sl<AuthRepository>().getUser();
  }
}
