import 'package:sage/domain/entities/auth/user.dart';

class UserModel {
  String? email;
  String? fullName;
  String? imageURL;
  bool isAdmin = false;

  UserModel({
    this.email,
    this.fullName,
    this.imageURL,
    this.isAdmin = false,
  });

  UserModel.fromJson(Map<String, dynamic> data) {
    email = data['email'];
    fullName = data['name'];
    imageURL = data['imageURL'];
    isAdmin = data['is_admin'] == true;
  }

  UserModel.fromApiJson(Map<String, dynamic> data) {
    email = data['email'];
    fullName = data['full_name'];
    imageURL = data['imageURL'];
    isAdmin = data['is_admin'] == true;
  }
}

extension UserModelX on UserModel {
  UserEntity toEntity() {
    return UserEntity(
      email: email!,
      fullName: fullName!,
      imageURL: imageURL!,
      isAdmin: isAdmin,
    );
  }
}
