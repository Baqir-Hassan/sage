import 'package:dartz/dartz.dart';
import 'package:sage/core/usecase/usecase.dart';
import 'package:sage/domain/repository/lecture/lecture.dart';
import 'package:sage/service_locator.dart';

class ToggleSavedLectureUseCase implements UseCase<Either, String> {
  @override
  Future<Either> call({String? params}) async {
    return await sl<LectureRepository>().toggleSavedLecture(params!);
  }
}
