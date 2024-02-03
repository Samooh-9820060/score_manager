import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:score_manager/widgets/ScoreManagerDialog.dart';

import '../models/Game.dart';
import '../models/Tournament.dart';
import '../services/GameService.dart';
import '../services/TournamentService.dart';

class AddGameForm extends StatefulWidget {
  final Tournament? tournament;

  AddGameForm({super.key, this.tournament});

  @override
  _AddGameFormState createState() => _AddGameFormState();
}

class _AddGameFormState extends State<AddGameForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _dateTimeController = TextEditingController();
  TextEditingController _timeController = TextEditingController();
  Map<String, TextEditingController> _scoreControllers = {};
  String? _selectedWinner;
  String? _selectedTournamentId;
  List<Tournament> availableTournaments = []; // List of available tournaments
  late Tournament selectedTournament;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null && pickedDate != DateTime.now()) {
      _dateTimeController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      _timeController.text = pickedTime.format(context);
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch available tournaments and set the default tournament if provided
    _fetchTournaments();

    // Schedule a post-frame callback to set initial values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _dateTimeController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
          _timeController.text = TimeOfDay.now().format(context);
        });
      }
    });

    if (widget.tournament != null) {
      _selectedTournamentId = widget.tournament!.id;
      selectedTournament = widget.tournament!;
      _initializeScoreControllers(widget.tournament!);
    }
  }

  void _onAddGamePressed() async {
    if (_formKey.currentState!.validate()) {
      try {
        String gameId = _firestore.collection('games').doc().id;
        Map<String, String> scores = {};
        String? winnerName;

        for (var participant in selectedTournament.participants) {
          String score = _scoreControllers[participant.name]!.text;
          scores[participant.name] = score;

          if (_selectedWinner == participant.name) {
            winnerName = participant.name;
          }
        }

        if (winnerName == null) {
          print('No winner selected');
          return;
        }

        // Convert the date and time to the correct format
        String formattedDate = _dateTimeController.text.replaceAll('-', '/');
        String formattedDateTime = '$formattedDate ${_timeController.text}';

        // Parse the date and time
        DateTime gameDateTime = DateFormat('dd/MM/yyyy HH:mm').parse(formattedDateTime);


        Game newGame = Game(
          id: gameId,
          tournamentId: _selectedTournamentId!,
          dateTime: gameDateTime,
          scores: scores,
          winnerName: winnerName,
          createdDate: DateTime.now(),
          createdBy: FirebaseAuth.instance.currentUser!.uid,
          lastModifiedBy: FirebaseAuth.instance.currentUser!.uid,
          lastModifiedDate: DateTime.now(),
        );

        await GameService().addGame(newGame);
        showInfoDialog('Add Game', 'Game has been succesfully added', true, context);
      } catch (e) {
        showInfoDialog('Add Game', 'Error Adding Game: $e', true, context);
      }
    }
  }

  void _initializeScoreControllers(Tournament tournament) {
    _scoreControllers.clear();
    _selectedWinner = null;

    for (var participant in tournament.participants) {
      var controller = TextEditingController();
      _scoreControllers[participant.name] = controller;

      // Adding a listener to each controller
      controller.addListener(() {
        _updateWinner();
      });
    }
  }

  void _updateWinner() {
    int highestScore = -1;
    String? highestScorerId;

    _scoreControllers.forEach((key, controller) {
      int? score = int.tryParse(controller.text);
      if (score != null && score > highestScore) {
        highestScore = score;
        highestScorerId = key;
      }
    });

    setState(() {
      _selectedWinner = highestScorerId;
    });
  }

  Future<void> _fetchTournaments() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    var stream = TournamentService().getEditableTournamentsStream(userId);

    stream.listen((tournaments) {
      DateTime now = DateTime.now();
      List<Tournament> activeTournaments = tournaments.where((tournament) {
        return (tournament.startDate != null && tournament.startDate!.isBefore(now)) &&
            (tournament.endDate == null || tournament.endDate!.isAfter(now));
      }).toList();

      setState(() {
        availableTournaments = tournaments;
        if (widget.tournament != null) {
          _selectedTournamentId = widget.tournament!.id;
          selectedTournament = widget.tournament!;
          _initializeScoreControllers(widget.tournament!);
        } else if (activeTournaments.length == 1) {
          // If there is only one active tournament, automatically select it
          _selectedTournamentId = activeTournaments.first.id;
          selectedTournament = activeTournaments.first;
          _initializeScoreControllers(activeTournaments.first);
        } else {
          //just select a random tournament
          _selectedTournamentId = availableTournaments.first.id;
          selectedTournament = availableTournaments.first;
          _initializeScoreControllers(availableTournaments.first);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Game'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  value: _selectedTournamentId,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTournamentId = newValue;
                      // Find the selected tournament and initialize score controllers
                      selectedTournament = availableTournaments.firstWhere(
                            (tournament) => tournament.id == newValue,
                        //orElse: () => null,
                      );
                      _scoreControllers.clear();
                      _initializeScoreControllers(selectedTournament);
                                        });
                  },
                  items: availableTournaments.map<DropdownMenuItem<String>>((Tournament tournament) {
                    return DropdownMenuItem<String>(
                      value: tournament.id,
                      child: Text(tournament.name),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Select Tournament',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _dateTimeController,
                  decoration: InputDecoration(
                    labelText: 'Game Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  readOnly: true,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: 'Game Time',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.access_time),
                      onPressed: () => _selectTime(context),
                    ),
                  ),
                  readOnly: true,
                ),
                SizedBox(height: 20),
                // Score fields for each participant
                ..._scoreControllers.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                            ),
                            child: Text(
                              entry.key,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                            ),
                            child: TextFormField(
                              controller: entry.value,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Score',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10), // Adjusted padding
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 20),
                if (_selectedTournamentId != null && availableTournaments.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedWinner,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedWinner = newValue;
                      });
                    },
                    items: availableTournaments
                        .firstWhere((tournament) => tournament.id == _selectedTournamentId)
                        .participants
                        .map<DropdownMenuItem<String>>((participant) {
                      return DropdownMenuItem<String>(
                        value: participant.name,
                        child: Text(participant.name),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Select Winner',
                      border: OutlineInputBorder(),
                    ),
                  ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _onAddGamePressed,
                    child: const Text('Add Game'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
