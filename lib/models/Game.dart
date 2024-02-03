import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String tournamentId;
  final DateTime dateTime;
  final Map<String, String> scores;
  final String winnerName;
  final Timestamp? createdDate;
  final String createdBy;
  final Timestamp? lastModifiedDate;
  final String? lastModifiedBy;

  Game({
    required this.id,
    required this.tournamentId,
    required this.dateTime,
    required this.scores,
    required this.winnerName,
    required this.createdDate,
    required this.createdBy,
    this.lastModifiedDate,
    this.lastModifiedBy,
  });

  factory Game.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Game(
      id: doc.id,
      tournamentId: data['tournamentId'],
      dateTime: DateTime.parse(data['dateTime']),
      scores: Map<String, String>.from(data['scores']),
      winnerName: data['winnerName'],
      createdDate: data['createdDate'],
      createdBy: data['createdBy'],
      lastModifiedDate: data['lastModifiedDate'],
      lastModifiedBy: data['lastModifiedBy'],
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'dateTime': dateTime.toIso8601String(),
      'scores': scores,
      'winnerName': winnerName,
      'createdDate': createdDate,
      'createdBy': createdBy,
      'lastModifiedDate': lastModifiedDate,
      'lastModifiedBy': lastModifiedBy,
    };
  }
}
