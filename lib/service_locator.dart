import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage/data/repository/auth/auth_repository_impl.dart';
import 'package:sage/data/repository/lecture/lecture_repository_impl.dart';
import 'package:sage/data/sources/auth/auth_api_service.dart';
import 'package:sage/data/sources/lecture/lecture_api_service.dart';
import 'package:sage/data/sources/offline/offline_audio_service.dart';
import 'package:sage/data/sources/upload/upload_api_service.dart';
import 'package:sage/domain/repository/auth/auth.dart';
import 'package:sage/domain/repository/lecture/lecture.dart';
import 'package:sage/domain/usecase/auth/get_user.dart';
import 'package:sage/domain/usecase/auth/signin.dart';
import 'package:sage/domain/usecase/auth/signup.dart';
import 'package:sage/domain/usecase/lecture/toggle_saved_lecture.dart';
import 'package:sage/domain/usecase/lecture/get_saved_lectures.dart';
import 'package:sage/domain/usecase/lecture/get_recent_lectures.dart';
import 'package:sage/domain/usecase/lecture/get_lecture_library.dart';
import 'package:sage/domain/usecase/lecture/is_saved_lecture.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final preferences = await SharedPreferences.getInstance();

  sl.registerSingleton<SharedPreferences>(
    preferences,
  );

  sl.registerSingleton<http.Client>(
    http.Client(),
  );

  sl.registerSingleton<AuthApiService>(
    AuthApiServiceImpl(
      client: sl<http.Client>(),
      preferences: sl<SharedPreferences>(),
    ),
  );

  sl.registerSingleton<LectureApiService>(
    LectureApiServiceImpl(
      client: sl<http.Client>(),
      preferences: sl<SharedPreferences>(),
    ),
  );

  sl.registerSingleton<UploadApiService>(
    UploadApiServiceImpl(
      client: sl<http.Client>(),
      preferences: sl<SharedPreferences>(),
    ),
  );

  sl.registerSingleton<OfflineAudioService>(
    OfflineAudioService(
      client: sl<http.Client>(),
      preferences: sl<SharedPreferences>(),
    ),
  );

  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(),
  );

  sl.registerSingleton<LectureRepository>(
    LectureRepositoryImpl(),
  );

  sl.registerSingleton<SignupUseCase>(
    SignupUseCase(),
  );

  sl.registerSingleton<SigninUseCase>(
    SigninUseCase(),
  );

  sl.registerSingleton<GetUserUseCase>(
    GetUserUseCase(),
  );

  sl.registerSingleton<GetRecentLecturesUseCase>(
    GetRecentLecturesUseCase(),
  );

  sl.registerSingleton<GetLectureLibraryUseCase>(
    GetLectureLibraryUseCase(),
  );

  sl.registerSingleton<ToggleSavedLectureUseCase>(
    ToggleSavedLectureUseCase(),
  );

  sl.registerSingleton<IsSavedLectureUseCase>(
    IsSavedLectureUseCase(),
  );

  sl.registerSingleton<GetSavedLecturesUseCase>(
    GetSavedLecturesUseCase(),
  );
}
