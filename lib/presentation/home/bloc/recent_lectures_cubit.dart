import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sage/domain/usecase/lecture/get_recent_lectures.dart';
import 'package:sage/presentation/home/bloc/recent_lectures_state.dart';
import 'package:sage/service_locator.dart';

class RecentLecturesCubit extends Cubit<RecentLecturesState> {
  RecentLecturesCubit() : super(RecentLecturesLoading());

  Future<void> getRecentLectures() async {
    var returnedLectures = await sl<GetRecentLecturesUseCase>().call();

    returnedLectures.fold(
      (l) {
        emit(RecentLecturesLoadFailure());
      },
      (data) {
        emit(
          RecentLecturesLoaded(lectures: data),
        );
      },
    );
  }
}
