import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Game.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addGame(Game game) async {
    await _firestore.collection('games').doc(game.id).set(game.toMap());
  }

// Other game-related methods can be added here (e.g., fetching games, updating games)
}
