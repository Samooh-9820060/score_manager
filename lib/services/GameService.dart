import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/Game.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addGame(Game game) async {
    await _firestore.collection('games').doc(game.id).set(game.toMap());
  }

  Future<List<Game>> fetchGamesForDate(DateTime date) async {
    List<Game> games = [];
    // Format the date to match the date format in Firestore
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    // Query Firestore for games on the selected date
    var querySnapshot = await _firestore.collection('games')
        .where('dateTime', isGreaterThanOrEqualTo: DateTime.parse(formattedDate))
        .where('dateTime', isLessThan: DateTime.parse(formattedDate).add(Duration(days: 1)))
        .get();

    // Convert each document to a Game object
    for (var doc in querySnapshot.docs) {
      games.add(Game.fromFirestore(doc));
    }

    return games;
  }


  Future<List<Game>> fetchGamesForDateAndTournament(DateTime date, String tournamentId) async {
    // Format the start and end of day in the same format as the Firestore 'dateTime' field
    var formatter = DateFormat('yyyy-MM-dd');
    var formattedDate = formatter.format(date);
    var startOfDayString = formattedDate + 'T00:00:00.000';
    var endOfDayString = formattedDate + 'T23:59:59.999';

    var querySnapshot = await _firestore
        .collection('games')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDayString)
        .where('dateTime', isLessThanOrEqualTo: endOfDayString)
        .get();

    return querySnapshot.docs.map((doc) => Game.fromFirestore(doc)).toList();
  }
}
