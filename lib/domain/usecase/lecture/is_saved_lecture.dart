import 'package:sage/core/usecase/usecase.dart';
import 'package:sage/domain/repository/lecture/lecture.dart';
import 'package:sage/service_locator.dart';

class IsSavedLectureUseCase implements UseCase<bool, String> {
  @override
  Future<bool> call({String? params}) async {
    return sl<LectureRepository>().isSavedLecture(params!);
  }
}
