import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:score_manager/screens/add_manual_score.dart';

import '../models/Participants.dart';
import '../models/Tournament.dart';

class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onEdit;
  final VoidCallback onInsertGame;
  final VoidCallback insertOtherScore;
  final VoidCallback onViewStats;
  final VoidCallback onDeleteTournament;
  final VoidCallback onSetDefault;
  final VoidCallback finishTournament;
  final bool isDefault;

  TournamentCard({
    required this.tournament,
    required this.onEdit,
    required this.onInsertGame,
    required this.insertOtherScore,
    required this.onViewStats,
    required this.onDeleteTournament,
    required this.onSetDefault,
    required this.finishTournament,
    this.isDefault = false,
  });

  String formatDate(DateTime? date) {
    return date != null ? DateFormat('dd MMM yyyy').format(date) : 'N/A';
  }

  String getWinnerDetails() {
    if (tournament.winner != null &&
        tournament.winner! < tournament.participants.length) {
      Participant winner = tournament.participants[tournament.winner!];
      return winner.name;
    }
    return 'No winner declared';
  }

  @override
  Widget build(BuildContext context) {
    bool hasWinner = tournament.winner != null &&
        tournament.winner! < tournament.participants.length;

    return GestureDetector(
      onTap: () async {
        onViewStats();
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          tournament.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        if (isDefault)
                          SizedBox(width: 8),
                        if (isDefault)
                          Icon(Icons.star, color: Colors.amber),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String result) {
                      switch (result) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'insert_game':
                          onInsertGame();
                          break;
                        case 'insert_other_score':
                          insertOtherScore();
                          break;
                        case 'view_stats':
                          onViewStats();
                          break;
                        case 'delete_tournament':
                          onDeleteTournament();
                          break;
                        case 'finish_tournament':
                          finishTournament();
                          break;
                        case 'set_default':
                          onSetDefault();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      List<PopupMenuEntry<String>> menuItems = [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit), // Edit icon
                            title: Text('Edit Tournament'),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'insert_game',
                          child: ListTile(
                            leading: Icon(Icons.add_circle_outline), // Insert/Add icon
                            title: Text('Insert Game'),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'insert_other_score',
                          child: ListTile(
                            leading: Icon(Icons.list), // List or Scoreboard icon
                            title: Text('Insert Other Scores / Wins'),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'view_stats',
                          child: ListTile(
                            leading: Icon(Icons.bar_chart), // Stats/Analytics icon
                            title: Text('View Stats'),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'finish_tournament',
                          child: ListTile(
                            leading: Icon(Icons.emoji_events),
                            title: Text('Finish Tournament'),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete_tournament',
                          child: ListTile(
                            leading: Icon(Icons.delete), // Delete icon
                            title: Text('Delete Tournament'),
                          ),
                        ),
                      ];

                      // Only add 'Set as Default' if not already the default tournament
                      if (!isDefault) {
                        menuItems.add(
                          PopupMenuItem<String>(
                            value: 'set_default',
                            child: ListTile(
                              leading: Icon(Icons.star_border), // Default/Star icon
                              title: Text('Set as Default'),
                            ),
                          ),
                        );
                      }

                      return menuItems;
                    },
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Created: ${formatDate(tournament.createdDate)}',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (tournament.startDate != null)
                    Expanded(
                      child: Text(
                        'Start: ${formatDate(tournament.startDate)}',
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      ),
                    ),
                  if (tournament.endDate != null)
                    Expanded(
                      child: Text(
                        'End: ${formatDate(tournament.endDate)}',
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      ),
                    ),
                ],
              ),
              if (hasWinner) // Display only if there is a winner
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber),
                      // Trophy icon
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Winner: ${getWinnerDetails()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
