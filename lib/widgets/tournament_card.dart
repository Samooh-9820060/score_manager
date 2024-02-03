import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/Participants.dart';
import '../models/Tournament.dart';

class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onEdit;
  final VoidCallback onInsertGame;
  final VoidCallback onViewStats;

  TournamentCard({
    required this.tournament,
    required this.onEdit,
    required this.onInsertGame,
    required this.onViewStats,
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
    bool hasWinner = tournament.winner != null && tournament.winner! < tournament.participants.length;

    return GestureDetector(
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('Choose an action'),
              children: <Widget>[
                SimpleDialogOption(
                  onPressed: () => {
                    Navigator.of(context).pop(),
                    onEdit(),
                  },
                  child: const Text('Edit Tournament'),
                ),
                SimpleDialogOption(
                  onPressed: () => onInsertGame,
                  child: const Text('Insert Game'),
                ),
                SimpleDialogOption(
                  onPressed: () => onViewStats,
                  child: const Text('View Stats'),
                ),
              ],
            );
          },
        );

        if (result != null) {
          switch (result) {
            case 'edit':
              onEdit();
              break;
            case 'insert_game':
              onInsertGame();
              break;
            case 'view_stats':
              onViewStats();
              break;
          }
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                tournament.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
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
                      Icon(Icons.emoji_events, color: Colors.amber), // Trophy icon
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
