import 'package:sage/core/usecase/usecase.dart';
import 'package:sage/domain/repository/auth/auth.dart';
import 'package:sage/service_locator.dart';

class SignoutUseCase implements UseCase<void, dynamic> {
  @override
  Future<void> call({params}) async {
    await sl<AuthRepository>().signout();
  }
}
