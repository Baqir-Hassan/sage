import 'package:dartz/dartz.dart';
import 'package:spotify_with_flutter/data/sources/song/song_api_service.dart';
import 'package:spotify_with_flutter/domain/repository/song/song.dart';
import 'package:spotify_with_flutter/service_locator.dart';

class SongRepositoryImpl extends SongsRepository {
  @override
  Future<Either> getNewsSongs() async {
    return await sl<SongApiService>().getNewsSongs();
  }

  @override
  Future<Either> getPlayList() async {
    return await sl<SongApiService>().getPlayList();
  }

  @override
  Future<Either> addOrRemoveFavoriteSong(String songId) async {
    return await sl<SongApiService>().addOrRemoveFavoriteSong(songId);
  }

  @override
  Future<bool> isFavoriteSong(String songId) async {
    return await sl<SongApiService>().isFavoriteSong(songId);
  }

  @override
  Future<Either> getUserFavoriteSongs() async {
    return await sl<SongApiService>().getUserFavoriteSong();
  }
}
