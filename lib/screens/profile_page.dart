import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:score_manager/widgets/ScoreManagerDialog.dart';

import 'SignIn.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? firebaseUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> userProfileData = {};
  bool isLoading = true;
  bool allowTournamentAddition = false; // Default value
  bool allowStatsViewing = false; // New option

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (firebaseUser != null) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          userProfileData = userDoc.data()!;
          isLoading = false;
          allowTournamentAddition = userProfileData['allowTournamentAddition'] ?? false;
          allowStatsViewing = userProfileData['allowStatsViewing'] ?? false; // Initialize with Firestore data
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                // Logic to change profile picture
              },
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userProfileData['profileImageUrl'] ?? 'https://via.placeholder.com/150'),
                backgroundColor: Colors.transparent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              userProfileData['username'] ?? 'Name',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              firebaseUser?.email ?? 'Email',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            _buildSwitchTile(
              'Allow other users to add me to tournaments',
              allowTournamentAddition,
                  (bool value) {
                setState(() {
                  allowTournamentAddition = value;
                });
              },
            ),
            _buildSwitchTile(
              'Let other players see my stats',
              allowStatsViewing,
                  (bool value) {
                setState(() {
                  allowStatsViewing = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: _updateUserProfile,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateUserProfile() async {
    if (firebaseUser != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(firebaseUser!.uid).update({
          'allowTournamentAddition': allowTournamentAddition,
          'allowStatsViewing': allowStatsViewing,
        });

        showInfoDialog('Update Profile', 'Profile updated successfully', false, context);
      } catch (e) {
        showInfoDialog('Update Profile', 'Error updating profile: $e', false, context);
      }
    }
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: SwitchListTile(
        title: Text(title),
        value: value,
        activeColor: Theme.of(context).primaryColor,
        onChanged: onChanged,
      ),
    );
  }
}

