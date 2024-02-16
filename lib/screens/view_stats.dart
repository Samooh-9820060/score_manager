import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:score_manager/models/UserProfile.dart';
import 'package:score_manager/services/TournamentService.dart';
import 'package:score_manager/widgets/ScoreManagerDialog.dart';
import '../models/Participants.dart';
import '../models/Tournament.dart';
import 'add_manual_score.dart';

class ParticipantScore {
  final String name;
  final int points;
  final int wins;
  final int totalScore;

  ParticipantScore({required this.name, required this.points, required this.wins, required this.totalScore});
}

class ViewStatsScreen extends StatefulWidget {
  final Tournament tournament;

  ViewStatsScreen({Key? key, required this.tournament}) : super(key: key);

  @override
  _ViewStatsScreenState createState() => _ViewStatsScreenState();
}

class _ViewStatsScreenState extends State<ViewStatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tournament.name} Scores'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pointFrequencyData')
                    .doc(widget.tournament.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: const CircularProgressIndicator());
                  }
                  var aggregatedData =
                      snapshot.data?.data() as Map<String, dynamic>? ?? {};

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('manualScoreEntries')
                        .doc(widget.tournament.id)
                        .get(),
                    builder: (context, manualScoresSnapshot) {
                      if (manualScoresSnapshot.hasError) {
                        return Text('Error: ${manualScoresSnapshot.error}');
                      }
                      if (manualScoresSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: const CircularProgressIndicator());
                      }
                      var manualScoresData =
                          manualScoresSnapshot.data?.data() as Map<String, dynamic>? ?? {};

                      var totalWins =
                      _aggregateWins(aggregatedData, widget.tournament.participants);

                      return _buildDataTable(_aggregateData(aggregatedData), totalWins, manualScoresData, aggregatedData);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _aggregateWins(
      Map<String, dynamic> data, List<Participant> participants) {
    Map<String, int> totalWins = {};

    // Initialize wins for each participant
    for (var participant in participants) {
      totalWins[participant.name] = 0;
    }

    data.forEach((date, dailyData) {
      if (dailyData is Map<String, dynamic> && dailyData.containsKey('wins')) {
        Map<dynamic, dynamic> wins = dailyData['wins'];
        if (wins.isNotEmpty) { // Check if there are valid wins
          wins.forEach((participantIndex, winCount) {
            String participantName = participants[int.parse(participantIndex)].name;
            // Explicitly cast winCount to int
            int winCountInt = (winCount as num).toInt();
            totalWins[participantName] = (totalWins[participantName] ?? 0) + winCountInt;
          });
        }
      }
    });

    return totalWins;
  }

  Map<String, List<int>> _aggregateData(Map<String, dynamic> data) {
    Map<String, List<int>> dailyPoints = {};

    data.forEach((date, dailyData) {
      if (dailyData is Map<String, dynamic> &&
          dailyData.containsKey('scores')) {
        var scores = dailyData['scores'] as Map<String, dynamic>;

        int totalScore = scores.values.fold(0, (sum, score) => sum + (int.tryParse(score.toString()) ?? 0));

        if (totalScore > 0) {
          // Sorting the scores
          var sortedScores = scores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          sortedScores.asMap().forEach((rank, entry) {
            var participantName =
                widget.tournament.participants[int.parse(entry.key)].name;

            // Ensure rank is within the bounds of pointValues list
            if (rank < widget.tournament.pointValues.length) {
              var points = widget.tournament.pointValues[rank];
              if (!dailyPoints.containsKey(participantName)) {
                dailyPoints[participantName] = [];
              }
              dailyPoints[participantName]!.add(points);
            } else {
              if (!dailyPoints.containsKey(participantName)) {
                dailyPoints[participantName] = [];
              }
              dailyPoints[participantName]!.add(0);            }
          });
        }
      }
    });
    return dailyPoints;
  }

  int _calculateTotalPoints(
      String participantName, Map<String, List<int>> aggregatedData) {
    int totalPoints = 0;
    if (aggregatedData.containsKey(participantName)) {
      totalPoints = aggregatedData[participantName]!.reduce((a, b) => a + b);
    }
    return totalPoints;
  }

  void _showManualPoints(BuildContext context) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    var tournamentId = widget.tournament?.id;

    // Fetch data from Firestore
    var snapshot = await firestore
        .collection('manualScoreEntries')
        .doc(tournamentId)
        .get();
    var data = snapshot.data() ?? {};
    var entries = data.entries.toList();

    // Show dialog with the data
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manual Score Entries'),
          content: SingleChildScrollView(
            child: entries.isNotEmpty
                ? ListBody(
                    children: entries.map((entry) {
                      var entryData = entry.value as Map<String, dynamic>;
                      String participantName = 'Unknown Participant';
                      int? participantIndex = entryData['participantIndex'];
                      if (participantIndex != null &&
                          participantIndex >= 0 &&
                          participantIndex <
                              widget.tournament!.participants.length) {
                        participantName = widget
                            .tournament!.participants[participantIndex].name;
                      }

                      // Format the date/time
                      String dateTime = entryData['dateTime'] ?? 'Unknown Date';
                      try {
                        DateTime parsedDate =
                            DateFormat('yyyy-MM-dd – kk:mm').parse(dateTime);
                        dateTime =
                            DateFormat('yyyy-MM-dd hh:mm a').format(parsedDate);
                      } catch (e) {
                        // Keep dateTime as is if parsing fails
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => InsertOtherScoresScreen(
                                      tournament: widget.tournament,
                                      manualScoreEntry: entry.key,
                                    )),
                          );
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Type: ${entryData['typeToAdd'] ?? 'Unknown'}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('Participant: $participantName'),
                                Text('Reason: ${entryData['reason']}'),
                                Text('Value: ${entryData['value']}'),
                                Text('Date: $dateTime'),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Center(
                    child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('There are no entries',
                        style: TextStyle(fontSize: 16)),
                  )),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRecalculateScores(BuildContext context) async {
    bool confirm = await showConfirmDialog(
        'Recalculate Scores',
        'This will recalculate the scores and reset it. Are you sure you want to continue?',
        context
    );

    if (confirm) {
      // Call the method to recalculate and refresh scores
      TournamentService().recalculateAndRefreshScores(widget.tournament, context);
    }
  }

  Widget _buildDataTable(
      Map<String, List<int>> aggregatedData, Map<String, int> winsData, Map<String, dynamic> manualScoresData, Map<String, dynamic> totalData) {

    // Map participant index to name
    Map<int, String> indexToNameMap = {};
    for (var i = 0; i < widget.tournament.participants.length; i++) {
      indexToNameMap[i] = widget.tournament.participants[i].name;
    }

    // Function to calculate total points including manual adjustments
    int calculateTotalPoints(String participantName, Map<String, List<int>> data, Map<String, dynamic> manualScores) {
      int points = _calculateTotalPoints(participantName, data);
      manualScores.forEach((key, value) {
        if (indexToNameMap[value['participantIndex']] == participantName && value['typeToAdd'] == 'Points') {
          points += int.parse(value['value']);
        }
      });
      return points;
    }

    // Function to calculate total wins including manual adjustments
    int calculateTotalWins(String participantName, Map<String, int> data, Map<String, dynamic> manualScores) {
      int wins = data[participantName] ?? 0;
      manualScores.forEach((key, value) {
        if (indexToNameMap[value['participantIndex']] == participantName && value['typeToAdd'] == 'Wins') {
          wins += int.parse(value['value']);
        }
      });
      return wins;
    }

    int calculateTotalScore(String participantName, Map<String, dynamic> fullData, Map<int, String> indexToNameMap) {
      int totalScore = 0;

      fullData.forEach((date, dataMap) {
        Map<dynamic, dynamic> scores = dataMap['scores'];
        scores.forEach((index, score) {
          // Convert index to int before lookup if it's not already an int
          int participantIndex = int.tryParse(index.toString()) ?? -1; // Handle potential parsing failure
          String? participantNameAtIndex = indexToNameMap[participantIndex];

          if (participantNameAtIndex == participantName) {
            // Add the score to the total score
            totalScore += score as int; // Ensure score is an integer
          }
        });
      });
      return totalScore;
    }

    // Create a list of ParticipantScore objects
    var participantScores = aggregatedData.entries.map((entry) {
      var participantName = entry.key;
      int points = calculateTotalPoints(participantName, aggregatedData, manualScoresData);
      int wins = calculateTotalWins(participantName, winsData, manualScoresData);
      int totalScore = calculateTotalScore(participantName, totalData, indexToNameMap);
      return ParticipantScore(name: participantName, points: points, wins: wins, totalScore: totalScore);
    }).toList();

    // Sort the list based on points in descending order
    participantScores.sort((a, b) => b.points.compareTo(a.points));

    List<DataRow> rows = participantScores.map<DataRow>((participant) {
      bool isCurrentUser = participant.name == UserProfileSingleton().username;
      return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (isCurrentUser) return Colors.lightBlue[100]; // Mint green
            return null;
          },
        ),
        cells: [
          DataCell(Text(participant.name)),
          DataCell(Center(child: Text(participant.points.toString(), textAlign: TextAlign.center))),
          DataCell(Center(child: Text(participant.wins.toString(), textAlign: TextAlign.center))),
          DataCell(Center(child: Text(participant.totalScore.toString(), textAlign: TextAlign.center))),
        ],
      );
    }).toList();

    List<DataColumn> columns = [
      const DataColumn(label: Text('Participant')),
      const DataColumn(label: Text('Points')),
      const DataColumn(label: Text('Total Wins')),
      const DataColumn(label: Text('Total Score')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scores (${widget.tournament.scoringMethod} - ${widget.tournament.pointCalculationFrequency})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String result) {
                  switch (result) {
                    case 'manual_points':
                      _showManualPoints(context);
                      break;
                    case 'recalculate_scores':
                      _confirmRecalculateScores(context);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'manual_points',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.menu_book_outlined),
                        SizedBox(width: 8),
                        Text('Show Manual Points'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'recalculate_scores',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Recalculate Scores'),
                      ],
                    ),
                  ),
                ],
                icon: Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
        FractionallySizedBox(
          widthFactor: 1.0, // 100% width
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.transparent, width: 0.5),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Enable horizontal scrolling
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: DataTable(
                  columns: columns,
                  rows: rows,
                  columnSpacing: 10,
                  dataRowHeight: 40,
                  headingRowHeight: 48,
                  headingRowColor:
                      MaterialStateProperty.all(Colors.blueGrey[100]),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueGrey[300]!, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
