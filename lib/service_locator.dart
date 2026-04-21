import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify_with_flutter/data/repository/auth/auth_repository_impl.dart';
import 'package:spotify_with_flutter/data/repository/song/song_repository_impl.dart';
import 'package:spotify_with_flutter/data/sources/auth/auth_api_service.dart';
import 'package:spotify_with_flutter/data/sources/song/song_api_service.dart';
import 'package:spotify_with_flutter/data/sources/upload/upload_api_service.dart';
import 'package:spotify_with_flutter/domain/repository/auth/auth.dart';
import 'package:spotify_with_flutter/domain/repository/song/song.dart';
import 'package:spotify_with_flutter/domain/usecase/auth/get_user.dart';
import 'package:spotify_with_flutter/domain/usecase/auth/signin.dart';
import 'package:spotify_with_flutter/domain/usecase/auth/signup.dart';
import 'package:spotify_with_flutter/domain/usecase/song/add_or_remove_favorite_song.dart';
import 'package:spotify_with_flutter/domain/usecase/song/get_favorite_songs.dart';
import 'package:spotify_with_flutter/domain/usecase/song/get_news_songs.dart';
import 'package:spotify_with_flutter/domain/usecase/song/get_play_list.dart';
import 'package:spotify_with_flutter/domain/usecase/song/is_favorite_song.dart';

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

  sl.registerSingleton<SongApiService>(
    SongApiServiceImpl(
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

  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(),
  );

  sl.registerSingleton<SongsRepository>(
    SongRepositoryImpl(),
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

  sl.registerSingleton<GetNewsSongsUseCase>(
    GetNewsSongsUseCase(),
  );

  sl.registerSingleton<GetPlayListUseCase>(
    GetPlayListUseCase(),
  );

  sl.registerSingleton<AddOrRemoveFavoriteSongUseCase>(
    AddOrRemoveFavoriteSongUseCase(),
  );

  sl.registerSingleton<IsFavoriteSongUseCase>(
    IsFavoriteSongUseCase(),
  );

  sl.registerSingleton<GetFavoriteSongsUseCase>(
    GetFavoriteSongsUseCase(),
  );
}
