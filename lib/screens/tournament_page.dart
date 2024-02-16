import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score_manager/screens/add_manual_score.dart';
import 'package:score_manager/screens/game_form.dart';
import 'package:score_manager/screens/view_stats.dart';
import 'package:score_manager/widgets/ScoreManagerDialog.dart';

import '../models/Tournament.dart';
import '../services/TournamentService.dart';
import '../widgets/tournament_card.dart';
import 'create_tournament.dart';

class TournamentListPage extends StatefulWidget {
  @override
  _TournamentListPageState createState() => _TournamentListPageState();
}

class _TournamentListPageState extends State<TournamentListPage> {
  late final Stream<List<Tournament>> _tournamentStream;
  String? currentUserUid;
  String? defaultTournamentId;

  @override
  void initState() {
    super.initState();
    currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid != null) {
      _tournamentStream = TournamentService().getEditableTournamentsStream(currentUserUid!);
      getDefaultTournamentId();
    }
  }

  getDefaultTournamentId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultTournamentId = prefs.getString('defaultTournamentId');
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
                onInsertGame: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddGameForm(tournament: tournament)),
                  );
                },
                insertOtherScore: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InsertOtherScoresScreen(tournament: tournament)),
                  );
                },
                onViewStats: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewStatsScreen(tournament: tournament,)),
                  );
                },
                onDeleteTournament: () async {
                  if (tournament.createdBy != currentUserUid) {
                    showInfoDialog('Delete Tournament', 'Only the creator can delete the tournament', false, context);
                    return;
                  }

                  // Show a confirmation dialog before deleting
                  bool confirmDelete = await showConfirmDialog(
                      'Delete Tournament',
                      'Are you sure you want to delete this tournament? This will delete all associated games as well!',
                      context
                  );

                  if (confirmDelete) {
                    await TournamentService().deleteTournament(tournament.id);
                    showInfoDialog('Delete Tournament', 'Tournament has been deleted with all associated games', false, context);
                  }
                },
                onSetDefault: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('defaultTournamentId', tournament.id);
                  getDefaultTournamentId();
                  showInfoDialog('Set Default Tournament', 'Tournament has been set as default and will be always seleceted when inserting games', false, context);
                },
                isDefault: tournament.id == defaultTournamentId,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
