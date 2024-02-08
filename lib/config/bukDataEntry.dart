import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Future<void> addEntries(List<String> entries) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  WriteBatch batch = firestore.batch();

  for (String entry in entries) {
    Map<String, dynamic> gameData = parseEntry(entry);
    DocumentReference docRef = firestore.collection('games').doc(); // New document reference
    batch.set(docRef, gameData);
  }

  await batch.commit();
}

Map<String, dynamic> parseEntry(String entry) {
  List<String> parts = entry.split('\t');
  DateFormat dateFormat = DateFormat('dd-MMM-yyyy HH:mm:ss');

  DateTime dateTime = dateFormat.parse('${parts[1]} ${parts[2]}');
  Map<String, String> scores = {
    '0': parts[7],
    '1': parts[6],
    '2': parts[5],
    '3': parts[4]
  };
  int winnerIndex = int.parse(parts[8]);

  return {
    'dateTime': dateTime.toIso8601String(),
    'scores': scores,
    'winnerIndex': winnerIndex,
    'tournamentId': 'BEKHPrAb7oZejZZC1qlh',
    'createdBy': 'Vd1I406c1aPTMLVAjvvgfF1j3lF3',
    'lastModifiedBy': 'Vd1I406c1aPTMLVAjvvgfF1j3lF3',
    'createdDate': Timestamp.now(),
    'lastModifiedDate': Timestamp.now(),
  };
}
