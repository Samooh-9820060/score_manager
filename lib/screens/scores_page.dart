import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Game.dart';
import '../models/Tournament.dart';
import '../services/GameService.dart';
import '../services/TournamentService.dart';
import 'game_form.dart';

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
    //_fetchGamesForSelectedFilters();
    _fetchTournaments();
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
        if (tournaments.isNotEmpty && selectedTournamentId == null) {
          selectedTournamentId = tournaments.first.id;
          _fetchGamesForSelectedFilters(); // Fetch games for the first tournament
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

    participantScores = {
      'scores': scores,
      'wins': wins,
    };
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

    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (selectedTournamentId != null && games.isEmpty) {
      //_fetchGamesForSelectedFilters();
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<List<Tournament>>(
                    stream: TournamentService()
                        .getEditableTournamentsStream(userId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return const Center(
                              child: CircularProgressIndicator());
                        default:
                          return buildTournamentDropdown(snapshot.data ?? []);
                      }
                    },
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
                        : // StreamBuilder for pointFrequencyData
                        StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('pointFrequencyData')
                                .doc(selectedTournamentId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              // Fetch tournament data
                              return FutureBuilder<Tournament?>(
                                future: TournamentService().fetchTournamentById(
                                    selectedTournamentId ?? ''),
                                builder: (context, tournamentSnapshot) {
                                  if (tournamentSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (tournamentSnapshot.hasError ||
                                      tournamentSnapshot.data == null) {
                                    return Text(
                                        'Error fetching tournament data');
                                  }

                                  return buildScoresDataTable(snapshot.data,
                                      columns, tournamentSnapshot.data!);
                                },
                              );
                            },
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
                  : StreamBuilder<List<Game>>(
                      stream: GameService().fetchGamesStream(
                          selectedDate, selectedTournamentId ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return const CircularProgressIndicator();
                          default:
                            games = snapshot.data ?? [];
                            calculateScoresAndWins();
                            return buildGamesList(
                                games); // Implement this method
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTournamentDropdown(List<Tournament> tournaments) {
    List<DropdownMenuItem<String>> dropdownItems = tournaments
        .map((tournament) => DropdownMenuItem<String>(
              value: tournament.id,
              child: Text(tournament.name),
            ))
        .toList();

    return Flexible(
      child: DropdownButton<String>(
        isExpanded: true,
        value: selectedTournamentId,
        onChanged: (String? newValue) {
          setState(() {
            selectedTournamentId = newValue;
            _fetchGamesForSelectedFilters();
          });
        },
        items: dropdownItems,
      ),
    );
  }

  Widget buildGamesList(List<Game> games) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      // keeps it from scrolling independently
      itemCount: games.length,
      itemBuilder: (context, index) {
        Game game = games[index];
        return GameCard(
            game: game); // Implement GameCard according to your game model
      },
    );
  }

  Widget buildScoresDataTable(DocumentSnapshot? pointFrequencyData,
      List<DataColumn> columns, Tournament tournament) {
    // Check if there is data for the selected date and cast it to a Map
    var snapshotData = pointFrequencyData?.data();
    if (snapshotData is! Map<String, dynamic>) {
      return Text('Invalid data format');
    }

    String formattedDateKey = DateFormat('yyyy-M-d').format(selectedDate);
    var dailyData = snapshotData[formattedDateKey] as Map?;

    if (dailyData == null) {
      return Text('No data for $formattedDateKey');
    }

    List<DataRow> rows = [];
    Map scores = dailyData['scores'] as Map<dynamic, dynamic>;
    Map wins = dailyData['wins'] as Map<dynamic, dynamic>;

    scores.forEach((index, score) {
      int winCount = wins[index] ?? 0;
      String participantName =
          tournament.participants[int.parse(index.toString())].name;
      rows.add(DataRow(
        cells: [
          DataCell(Text(participantName)),
          DataCell(Text(score.toString())),
          DataCell(Text(winCount.toString())),
        ],
      ));
    });

    return DataTable(
      columnSpacing: 10,
      dataRowHeight: 40,
      headingRowHeight: 48,
      headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
      headingTextStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
      columns: columns,
      rows: rows,
    );
  }
}

void onDeleteGame(String gameId) async {
  // Instantiate your GameService
  var gameService = GameService();

  // Call the deleteGame method
  await gameService.deleteGame(gameId);
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

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddGameForm(game: game),
          ),
        );
      },
      onLongPress: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Game'),
              content: const Text('Are you sure you want to delete this game?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onDeleteGame(game.id);
                  },
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
        if (result == true) {
          // Perform the deletion if the user confirms
          onDeleteGame(game.id);
        }
      },
      child: Card(
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
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 10),
              ...scoreWidgets,
            ],
          ),
        ),
      ),
    );
  }
}
