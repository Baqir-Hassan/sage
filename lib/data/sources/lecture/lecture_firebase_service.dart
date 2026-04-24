import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sage/data/models/lectures/lecture_model.dart';
import 'package:sage/domain/entities/lectures/lecture.dart';
import 'package:sage/domain/usecase/lecture/is_saved_lecture.dart';
import 'package:sage/service_locator.dart';

abstract class LectureFirebaseService {
  Future<Either> getRecentLectures();
  Future<Either> getLectureLibrary();
  Future<Either> toggleSavedLecture(String lectureId);
  Future<bool> isSavedLecture(String lectureId);
  Future<Either> getSavedLectures();
}

class LectureFirebaseServiceImpl extends LectureFirebaseService {
  @override
  Future<Either> getRecentLectures() async {
    try {
      List<LectureEntity> lectures = [];
      var data = await FirebaseFirestore.instance
          .collection('Songs')
          .orderBy(
            'releaseDate',
            descending: true,
          )
          .limit(3)
          .get();

      for (var element in data.docs) {
        var lectureModel = LectureModel.fromJson(element.data());
        bool isSaved = await sl<IsSavedLectureUseCase>().call(
          params: element.reference.id,
        );
        lectureModel.isSaved = isSaved;
        lectureModel.lectureId = element.reference.id;
        lectures.add(
          lectureModel.toEntity(),
        );
      }

      return right(lectures);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      return const Left('An error occurred, Please try again.');
    }
  }

  @override
  Future<Either> getLectureLibrary() async {
    try {
      List<LectureEntity> lectures = [];
      var data = await FirebaseFirestore.instance
          .collection('Songs')
          .orderBy(
            'releaseDate',
            descending: true,
          )
          .get();

      for (var element in data.docs) {
        var lectureModel = LectureModel.fromJson(element.data());

        bool isSaved = await sl<IsSavedLectureUseCase>().call(
          params: element.reference.id,
        );
        lectureModel.isSaved = isSaved;
        lectureModel.lectureId = element.reference.id;

        lectures.add(
          lectureModel.toEntity(),
        );
      }

      return right(lectures);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      return const Left('An error occurred, Please try again.');
    }
  }

  @override
  Future<Either> toggleSavedLecture(String lectureId) async {
    try {
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

      final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

      late bool isSaved;

      var user = firebaseAuth.currentUser;

      String uID = user!.uid;

      QuerySnapshot savedLectures = await firebaseFirestore
          .collection('Users')
          .doc(uID)
          .collection('Favorites')
          .where(
            'lectureId',
            isEqualTo: lectureId,
          )
          .get();

      if (savedLectures.docs.isNotEmpty) {
        await savedLectures.docs.first.reference.delete();
        isSaved = false;
      } else {
        await firebaseFirestore
            .collection('Users')
            .doc(uID)
            .collection('Favorites')
            .add(
          {
            'lectureId': lectureId,
            'addedDate': Timestamp.now(),
          },
        );
        isSaved = true;
      }

      return Right(isSaved);
    } catch (e) {
      return const Left('An error occurred');
    }
  }

  @override
  Future<bool> isSavedLecture(String lectureId) async {
    try {
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

      final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

      var user = firebaseAuth.currentUser;

      String uID = user!.uid;

      QuerySnapshot savedLectures = await firebaseFirestore
          .collection('Users')
          .doc(uID)
          .collection('Favorites')
          .where(
            'lectureId',
            isEqualTo: lectureId,
          )
          .get();

      if (savedLectures.docs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either> getSavedLectures() async {
    try {
      List<LectureEntity> savedLectures = [];
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

      final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

      var user = firebaseAuth.currentUser;

      String uID = user!.uid;

      QuerySnapshot savedLectureSnapshot = await firebaseFirestore
          .collection('Users')
          .doc(uID)
          .collection('Favorites')
          .get();

      for (var element in savedLectureSnapshot.docs) {
        String lectureId = element['lectureId'];
        var lectureDocument =
            await firebaseFirestore.collection('Songs').doc(lectureId).get();
        LectureModel lectureModel = LectureModel.fromJson(lectureDocument.data()!);
        lectureModel.isSaved = true;
        lectureModel.lectureId = lectureId;
        savedLectures.add(lectureModel.toEntity());
      }

      return Right(savedLectures);
    } catch (e) {
      return const Left('An error occurred');
    }
  }
}
