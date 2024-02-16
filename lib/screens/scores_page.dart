import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:score_manager/models/UserProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _fetchTournaments();
    getDefaultTournamentId();
  }

  void _fetchCurrentUserName() {
    var user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserName = user?.displayName ?? 'User';
    });
  }

  void getDefaultTournamentId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        selectedTournamentId = prefs.getString('defaultTournamentId');
      });
      _fetchGamesForSelectedFilters();
    } on Exception catch (_, e) {

    }
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
          selectedDate, selectedTournamentId!);

      // Sort the fetched games in descending order by dateTime
      fetchedGames.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      setState(() {
        games = fetchedGames;
        calculateScoresAndWins();
      });
    }
  }


  Map<String, dynamic> participantScores = {};

  void calculateScoresAndWins() {
    Map<int, int> scores = {};
    Map<int, int> wins = {};

    for (var game in games) {
      game.scores.forEach((participantIndexStr, scoreString) {
        int participantIndex = int.tryParse(participantIndexStr) ?? -1;
        int score = int.tryParse(scoreString) ?? 0; // Convert score to int

        if (participantIndex != -1) {
          scores[participantIndex] = (scores[participantIndex] ?? 0) + score;

          if (game.winnerIndex == participantIndex) {
            wins[participantIndex] = (wins[participantIndex] ?? 0) + 1;
          }
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
      const DataColumn(label: Text('Participant')),
      const DataColumn(label: Center(child: Text('Points')), numeric: true),
      const DataColumn(label: Center(child: Text('Wins')), numeric: true),
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
                            return FutureBuilder<Tournament?>(
                              future: TournamentService().fetchTournamentById(selectedTournamentId!),
                              builder: (context, tournamentSnapshot) {
                                if (tournamentSnapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }
                                if (tournamentSnapshot.hasError || tournamentSnapshot.data == null) {
                                  return Text('Error: Failed to fetch tournament data');
                                }
                                calculateScoresAndWins();
                                return buildGamesList(games, tournamentSnapshot.data!);
                              },
                            );
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

  // Updated buildGamesList method
  Widget buildGamesList(List<Game> games, Tournament tournament) {
    Map<int, String> participantIndexToName = {};
    for (int i = 0; i < tournament.participants.length; i++) {
      participantIndexToName[i] = tournament.participants[i].name;
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: games.length,
      itemBuilder: (context, index) {
        Game game = games[index];
        return GameCard(
          game: game,
          participantIndexToName: participantIndexToName,
        );
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

    String formattedDateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    var dailyData = snapshotData[formattedDateKey] as Map?;

    if (dailyData == null) {
      return Text('No data for $formattedDateKey');
    }

    List<DataRow> rows = [];
    Map scores = dailyData['scores'] as Map<dynamic, dynamic>;
    Map wins = dailyData['wins'] as Map<dynamic, dynamic>;

    // Sort scores by value in descending order
    var sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Create rows using sorted scores
    for (var entry in sortedScores) {
      int winCount = wins[entry.key] ?? 0;
      String participantName =
          tournament.participants[int.parse(entry.key.toString())].name;
      bool isCurrentUser = participantName == UserProfileSingleton().username;

      rows.add(DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (isCurrentUser) return Colors.lightBlue[100]; // Highlight color for current user
            return null;
          },
        ),
        cells: [
          DataCell(Text(participantName)),
          DataCell(Center(child: Text(entry.value.toString(), textAlign: TextAlign.center))),
          DataCell(Center(child: Text(winCount.toString(), textAlign: TextAlign.center))),
        ],
      ));
    }

    return DataTable(
      columnSpacing: 40,
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
  final Map<int, String> participantIndexToName; // Map of index to name

  GameCard({required this.game, required this.participantIndexToName});

  @override
  Widget build(BuildContext context) {
    List<Widget> scoreWidgets = game.scores.entries.map((entry) {
      int participantIndex = int.tryParse(entry.key) ?? -1;
      bool isWinner = game.winnerIndex == participantIndex;
      Color rowColor = isWinner ? Colors.green : Colors.black;
      String participantName = participantIndexToName[participantIndex] ?? 'Unknown';

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            participantName, // Participant's name or ID
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
