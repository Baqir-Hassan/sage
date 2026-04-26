class UserEntity {
  String? imageURL;
  String? fullName;
  String? email;
  bool isAdmin;

  UserEntity({
    this.imageURL,
    this.fullName,
    this.email,
    this.isAdmin = false,
  });
}
