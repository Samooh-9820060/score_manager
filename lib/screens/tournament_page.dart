import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:score_manager/widgets/ScoreManagerDialog.dart';

import '../models/Tournament.dart';
import '../widgets/tournament_card.dart';
import 'create_tournament.dart';

class TournamentListPage extends StatefulWidget {
  @override
  _TournamentListPageState createState() => _TournamentListPageState();
}

class _TournamentListPageState extends State<TournamentListPage> {
  late final Stream<QuerySnapshot> _tournamentStream;

  @override
  void initState() {
    super.initState();
    _tournamentStream =
        FirebaseFirestore.instance.collection('tournaments').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _tournamentStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('You have not been in any tournaments'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Tournament tournament = Tournament.fromFirestore(document);
              return TournamentCard(
                tournament: tournament,
                onEdit: () {
                  // Check if the current user is the creator of the tournament
                  String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? "";
                  if (tournament.createdBy == currentUserUid) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TournamentCreationForm(tournament: tournament))
                    );
                  } else {
                    // Show an unauthorized message
                    showInfoDialog('Edit Tournament', 'You are not authorized to edit this tournament', false, context);
                  }
                },
                onInsertGame: () {},
                onViewStats: () {},
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
