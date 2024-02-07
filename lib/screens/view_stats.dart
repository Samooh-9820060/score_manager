import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:score_manager/services/TournamentService.dart';
import 'package:score_manager/widgets/ScoreManagerDialog.dart';
import '../models/Participants.dart';
import '../models/Tournament.dart';
import 'add_manual_score.dart';

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
                    return const CircularProgressIndicator();
                  }
                  var data =
                      snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  var aggregatedData = _aggregateData(data);
                  var totalWins =
                      _aggregateWins(data, widget.tournament.participants);
                  return _buildDataTable(aggregatedData, totalWins);
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
        wins.forEach((participantIndex, winCount) {
          String participantName =
              participants[int.parse(participantIndex)].name;
          // Explicitly cast winCount to int
          int winCountInt = (winCount as num).toInt();
          totalWins[participantName] =
              (totalWins[participantName] ?? 0) + winCountInt;
        });
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
          }
        });
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

  Widget _buildDataTable(
      Map<String, List<int>> aggregatedData, Map<String, int> winsData) {
    List<DataRow> rows = aggregatedData.entries.map<DataRow>((entry) {
      var participantName = entry.key;
      var points = _calculateTotalPoints(participantName, aggregatedData);
      var wins = winsData[participantName] ?? 0;

      return DataRow(
        cells: [
          DataCell(Text(participantName)),
          DataCell(Center(
              child: Text(points.toString(), textAlign: TextAlign.center))),
          DataCell(Center(
              child: Text(wins.toString(), textAlign: TextAlign.center))),
        ],
      );
    }).toList();

    List<DataColumn> columns = [
      const DataColumn(label: Text('Participant')),
      const DataColumn(label: Text('Points')),
      const DataColumn(label: Text('Total Wins')),
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
              IconButton(
                icon: Icon(Icons.menu_book_outlined),
                onPressed: () async {
                  //show manually added points
                  _showManualPoints(context);
                },
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () async {
                  if (await showConfirmDialog(
                      'Recalculate Scores',
                      'This will recalculate the scores and reset it. Are you sure u want to continue?',
                      context)) {
                    TournamentService().recalculateAndRefreshScores(
                        widget.tournament, context);
                  }
                },
              ),
            ],
          ),
        ),
        FractionallySizedBox(
          widthFactor: 1.0, // 100% width
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.blueGrey[300]!, width: 0.5),
              color: Colors.white,
            ),
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
      ],
    );
  }
}
