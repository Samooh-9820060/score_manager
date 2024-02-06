import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:score_manager/services/GameService.dart';
import 'package:score_manager/widgets/ScoreManagerDialog.dart';
import '../models/Game.dart';
import '../models/Tournament.dart';

class TournamentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Tournament>> getEditableTournamentsStream(String userId) {
    var createdByStream = _firestore
        .collection('tournaments')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Tournament.fromFirestore(doc)).toList());

    var viewTournamentStream = _firestore
        .collection('tournaments')
        .where('viewTournament', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Tournament.fromFirestore(doc)).toList());

    return Rx.combineLatest2(createdByStream, viewTournamentStream, (List<Tournament> a, List<Tournament> b) {
      var combinedMap = <String, Tournament>{};
      for (var tournament in [...a, ...b]) {
        combinedMap[tournament.id] = tournament;
      }
      var combinedList = combinedMap.values.toList();
      combinedList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return combinedList;
    });
  }

  Future<Tournament?> fetchTournamentById(String tournamentId) async {
    try {
      var docSnapshot = await _firestore.collection('tournaments').doc(tournamentId).get();
      if (docSnapshot.exists) {
        return Tournament.fromFirestore(docSnapshot);
      }
    } catch (e) {
      // Handle errors or log them
      print('Error fetching tournament: $e');
    }
    return null;
  }

  Future<void> deleteTournament(String tournamentId) async {
    try {
      // Delete tournament
      await _firestore.collection('tournaments').doc(tournamentId).delete();

      // Additional clean-up if necessary, e.g., delete associated games
      // Example: Delete games associated with the tournament
      var gamesSnapshot = await _firestore.collection('games')
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      for (var doc in gamesSnapshot.docs) {
        await doc.reference.delete();
      }

    } catch (e) {
      print('Error deleting tournament: $e');
      // Handle errors or log them
    }
  }

  Map<String, dynamic> convertMapKeysToString(Map<dynamic, dynamic> map) {
    var newMap = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map) {
        // If the value is a map, convert its keys to strings recursively
        newMap[key.toString()] = convertMapKeysToString(value);
      } else {
        newMap[key.toString()] = value;
      }
    });
    return newMap;
  }


  Future<void> recalculateAndRefreshScores(Tournament tournament, BuildContext context) async {
    try {
      // Create a mapping from participant ID to their index
      Map<String, int> participantIndexes = {};
      for (int i = 0; i < tournament.participants.length; i++) {
        String participantName = tournament.participants[i].name; // Using name as the identifier
        participantIndexes[participantName] = i;
      }


      // Fetch all games for the tournament
      List<Game> games = await GameService().fetchAllGamesForTournament(tournament.id);

      // Organize games by date and calculate scores and wins
      Map<String, Map<String, dynamic>>? organizedData = {};
      for (var game in games) {
        String dateKey = DateFormat('yyyy-MM-dd').format(game.dateTime);
        if (!organizedData.containsKey(dateKey)) {
          organizedData[dateKey] = {
            'scores': {},
            'wins': {}
          };
        }

        // Update scores and wins for each participant in the game
        for (var entry in game.scores.entries) {
          String participantId = entry.key;
          int score = int.parse(entry.value);

          // Get the index of the participant
          int? participantIndex = participantIndexes[participantId];
          if (participantIndex == null) continue; // Skip if participant not found

          // Update scores
          if (!organizedData[dateKey]?['scores'].containsKey(participantIndex)) {
            organizedData[dateKey]?['scores'][participantIndex] = 0;
          }
          organizedData[dateKey]?['scores'][participantIndex] += score;

          // Update wins
          if (game.winnerName == participantId) {
            if (!organizedData[dateKey]?['wins'].containsKey(participantIndex)) {
              organizedData[dateKey]?['wins'][participantIndex] = 0;
            }
            organizedData[dateKey]?['wins'][participantIndex] += 1;
          }
        }
      }

      DocumentReference docRef = _firestore.collection('pointFrequencyData').doc(tournament.id);

      // Check if document exists
      var docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        // If document exists, delete existing data
        await docRef.delete();
      }

      // Add new data
      var convertedData = convertMapKeysToString(organizedData);
      await docRef.set(convertedData);

      showInfoDialog('Sync Data', 'Data Successfully Updated from DB', false, context);
    } catch (e) {
      showInfoDialog('Sync Data', 'Error recalculating scores: $e', false, context);
    }
  }
}
