import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Game.dart';
import '../models/Tournament.dart';
import '../services/GameService.dart';
import '../services/TournamentService.dart';

class ScoresPage extends StatefulWidget {
  @override
  _ScoresPageState createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
  DateTime selectedDate = DateTime.now();
  String? currentUserName;
  String? selectedTournamentId;
  List<Game> games = [];
  List<Tournament> tournaments = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
    _fetchTournaments();
    _fetchGamesForSelectedFilters();
  }

  void _fetchCurrentUserName() {
    var user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserName = user?.displayName ?? 'User';
    });
  }

  void _fetchTournaments() {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    var stream = TournamentService().getEditableTournamentsStream(userId);

    stream.listen((tournamentsData) {
      setState(() {
        tournaments = tournamentsData;
        if (tournaments.isNotEmpty) {
          selectedTournamentId = tournaments.first.id;
        }
      });
    });
  }

  void _fetchGamesForSelectedFilters() async {
    if (selectedTournamentId != null) {
      var fetchedGames = await GameService().fetchGamesForDateAndTournament(
          selectedDate, selectedTournamentId!); // Implement this method
      setState(() {
        games = fetchedGames;
        calculateScoresAndWins();
      });
    }
  }

  Map<String, dynamic> participantScores = {};

  void calculateScoresAndWins() {
    Map<String, int> scores = {};
    Map<String, int> wins = {};

    for (var game in games) {
      game.scores.forEach((participantId, scoreString) {
        int score = int.tryParse(scoreString) ?? 0; // Convert score to int
        scores[participantId] = (scores[participantId] ?? 0) + score;

        // Assuming game.winnerName holds the ID or name of the winning participant
        if (game.winnerName == participantId) {
          wins[participantId] = (wins[participantId] ?? 0) + 1;
        }
      });
    }

    setState(() {
      participantScores = {
        'scores': scores,
        'wins': wins,
      };
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        _fetchGamesForSelectedFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<DataColumn> columns = [
      const DataColumn(label: Center(child: Text('Participant'))),
      const DataColumn(label: Center(child: Text('Points'))),
      const DataColumn(label: Center(child: Text('Wins'))),
    ];

    List<DataRow> rows = participantScores['scores'] != null
        ? participantScores['scores']!.entries.map<DataRow>((entry) {
            var wins = participantScores['wins'][entry.key] ?? 0;
            return DataRow(
              cells: [
                DataCell(Text(entry.key, style: TextStyle(fontSize: 14))),
                DataCell(Text(entry.value.toString(),
                    style: const TextStyle(fontSize: 14))),
                DataCell(Text(wins.toString(), style: TextStyle(fontSize: 14))),
              ],
            );
          }).toList()
        : [];

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (tournaments.isNotEmpty)
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedTournamentId,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedTournamentId = newValue;
                              _fetchGamesForSelectedFilters();
                            });
                          },
                          items: tournaments.map<DropdownMenuItem<String>>(
                              (Tournament tournament) {
                            return DropdownMenuItem<String>(
                              value: tournament.id,
                              child: Text(tournament.name),
                            );
                          }).toList(),
                          underline: Container(), // Remove underline
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              FractionallySizedBox(
                widthFactor: 1.0, // 100% width
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    border:
                        Border.all(color: Colors.blueGrey[300]!, width: 0.5),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: games.isEmpty
                        ? Container()
                        : DataTable(
                            columnSpacing: 10,
                            dataRowHeight: 40,
                            headingRowHeight: 48,
                            headingRowColor:
                                MaterialStateProperty.all(Colors.blueGrey[50]),
                      headingTextStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors
                                  .black, // You can set your desired text color here
                            ),
                            columns: columns,
                            rows: rows,
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              games.isEmpty
                  ? Container()
                  : const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Games List',
                        style: TextStyle(
                          fontSize: 20, // Adjust the font size as needed
                          fontWeight: FontWeight.bold, // Add bold style
                          color: Colors.blue, // Change the text color
                        ),
                      ),
                    ),
              SizedBox(
                height: 10,
              ),
              games.isEmpty
                  ? Center(
                      child: Text(
                          'No games played on ${DateFormat('dd-MM-yyyy').format(selectedDate)}'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      // keeps it from scrolling independently
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        return GameCard(game: games[index]);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final Game game;

  GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    List<Widget> scoreWidgets = game.scores.entries.map((entry) {
      bool isWinner = entry.key == game.winnerName;
      Color rowColor = isWinner ? Colors.green : Colors.black;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            entry.key, // Participant's name or ID
            style: TextStyle(fontSize: 14, color: rowColor), // Apply the color
          ),
          Text(
            entry.value, // Participant's score
            style: TextStyle(fontSize: 14, color: rowColor), // Apply the color
          ),
        ],
      );
    }).toList();

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Time: ${DateFormat('dd-MM-yyyy HH:mm').format(game.dateTime)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey, // You can choose a color for the datetime text
              ),
            ),
            SizedBox(height: 10),
            ...scoreWidgets,

          ],
        ),
      ),
    );
  }
}
