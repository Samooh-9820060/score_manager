import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    _tournamentStream = FirebaseFirestore.instance.collection('tournaments').snapshots();
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TournamentCreationForm(tournament: tournament,))
                  );
                },
                onInsertGame: () {},
                onViewStats: () {},
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to tournament creation page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TournamentCreationForm()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Create Tournament',
      ),
    );
  }
}
