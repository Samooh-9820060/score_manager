// user_profile.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String? mail;
  final String? profileImageURL;

  UserProfile({this.id = '', required this.name, this.mail, this.profileImageURL});
}

class UserProfileSingleton {
  static final UserProfileSingleton _instance = UserProfileSingleton._internal();
  factory UserProfileSingleton() => _instance;

  UserProfileSingleton._internal();

  String? username;

  Future<void> fetchUserProfile() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        username = userDoc.data()?['username'];
      }
    }
  }
}
