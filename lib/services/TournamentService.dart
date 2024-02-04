import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
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

}
