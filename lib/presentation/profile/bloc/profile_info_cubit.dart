import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/domain/usecase/auth/get_user.dart';
import 'package:sage/presentation/profile/bloc/profile_info_state.dart';
import 'package:sage/service_locator.dart';

class ProfileInfoCubit extends Cubit<ProfileInfoState> {
  ProfileInfoCubit() : super(ProfileInfoLoading());

  Future<void> getUser() async {
    final user = await sl<GetUserUseCase>().call();

    user.fold(
      (_) {
        emit(
          ProfileInfoFailure(),
        );
      },
      (userEntity) {
        emit(
          ProfileInfoLoaded(userEntity: userEntity),
        );
      },
    );
  }
}
