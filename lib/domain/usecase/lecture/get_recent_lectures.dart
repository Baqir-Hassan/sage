import 'package:dartz/dartz.dart';
import 'package:sage/core/usecase/usecase.dart';
import 'package:sage/domain/repository/lecture/lecture.dart';
import 'package:sage/service_locator.dart';

class GetRecentLecturesUseCase implements UseCase<Either, dynamic> {
  @override
  Future<Either> call({params}) async {
    return sl<LectureRepository>().getRecentLectures();
  }
}
