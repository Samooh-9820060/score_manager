import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:score_manager/widgets/ScoreManagerDialog.dart';

import '../models/Tournament.dart';
import '../widgets/tournament_card.dart';
import 'create_tournament.dart';

class TournamentListPage extends StatefulWidget {
  @override
  _TournamentListPageState createState() => _TournamentListPageState();
}

class _TournamentListPageState extends State<TournamentListPage> {
  late final Stream<List<Tournament>> _tournamentStream;
  String? currentUserUid;

  @override
  void initState() {
    super.initState();
    currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid != null) {
      _tournamentStream = getTournamentsStream(currentUserUid!);
    }
  }

  Stream<List<Tournament>> getTournamentsStream(String userId) {
    var createdByStream = FirebaseFirestore.instance
        .collection('tournaments')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Tournament.fromFirestore(doc)).toList());

    var viewTournamentStream = FirebaseFirestore.instance
        .collection('tournaments')
        .where('viewTournament', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Tournament.fromFirestore(doc)).toList());

    return Rx.combineLatest2(createdByStream, viewTournamentStream, (List<Tournament> a, List<Tournament> b) {
      // Combine lists and remove duplicates
      var combinedMap = <String, Tournament>{};
      for (var tournament in [...a, ...b]) {
        combinedMap[tournament.id] = tournament;
      }

      // Convert to list and sort by createdDate in descending order
      var combinedList = combinedMap.values.toList();
      combinedList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return combinedList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Tournament>>(
        stream: _tournamentStream,
        builder: (BuildContext context, AsyncSnapshot<List<Tournament>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text('You have not been in any tournaments'));
          }

          return ListView(
            children: snapshot.data!.map((Tournament tournament) {
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
