// global.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Global {
  static String? currentUsername;

  static Future<void> fetchUserProfile() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        currentUsername = userDoc.data()?['username'];
      }
    }
  }
}
