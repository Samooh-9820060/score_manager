class UserProfile {
  final String id;
  final String name;
  final String? mail;
  final String? profileImageURL;

  UserProfile({this.id = '', required this.name, this.mail, this.profileImageURL});
}
