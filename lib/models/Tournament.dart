import 'package:cloud_firestore/cloud_firestore.dart';
import 'Participants.dart';

class Tournament {
  final String id;
  final String name;
  final DateTime? startDate; // Made nullable
  final DateTime? endDate; // Made nullable
  final List<Participant> participants;
  final String scoringMethod;
  final List<int> pointValues;
  final DateTime createdDate;
  final String createdBy;
  final int? winner;
  final List<String> viewTournament;

  Tournament({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.winner,
    this.participants = const [],
    required this.scoringMethod,
    required this.pointValues,
    required this.createdDate,
    required this.createdBy,
    this.viewTournament = const [],
  });

  factory Tournament.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<Participant> participants = (data['participants'] as List<dynamic>)
        .map((participantData) => Participant.fromMap(participantData as Map<String, dynamic>))
        .toList();

    // Extract non-null user ids from participants
    List<String> viewableUsers = participants
        .where((participant) => participant.id != null && participant.isRegisteredUser)
        .map((participant) => participant.id!)
        .toList();

    return Tournament(
      id: doc.id,
      name: data['name'] ?? '',
      startDate: data['startDate'] != null ? DateTime.parse(data['startDate']) : null,
      endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
      participants: participants,
      scoringMethod: data['scoringMethod'] ?? 'direct',
      pointValues: List<int>.from(data['pointValues'] ?? []),
      createdDate: DateTime.parse(data['createdDate']),
      createdBy: data['createdBy'] ?? '',
      winner: data['winner'],
      viewTournament: List<String>.from(data['viewTournament'] ?? viewableUsers),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'participants': participants.map((p) => p.toMap()).toList(),
      'scoringMethod': scoringMethod,
      'pointValues': pointValues,
      'createdDate': createdDate.toIso8601String(),
      'createdBy': createdBy,
      'winner': winner,
      'viewTournament': viewTournament,
    };
  }
}