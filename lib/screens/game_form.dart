import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/Tournament.dart';
import '../services/TournamentService.dart';

class AddGameForm extends StatefulWidget {
  final Tournament? tournament;

  AddGameForm({super.key, this.tournament});

  @override
  _AddGameFormState createState() => _AddGameFormState();
}

class _AddGameFormState extends State<AddGameForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _dateTimeController = TextEditingController();
  TextEditingController _timeController = TextEditingController();
  Map<String, TextEditingController> _scoreControllers = {};
  String? _selectedWinner;
  String? _selectedTournamentId;
  List<Tournament> availableTournaments = []; // List of available tournaments

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
      _initializeScoreControllers(widget.tournament!);
    }
  }

  void _initializeScoreControllers(Tournament tournament) {
    _scoreControllers.clear();
    for (var participant in tournament.participants) {
      _scoreControllers[participant.id == null ? participant.name : participant.name] = TextEditingController();
    }
  }

  Future<void> _fetchTournaments() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    var stream = TournamentService().getEditableTournamentsStream(userId);

    stream.listen((tournaments) {
      setState(() {
        availableTournaments = tournaments;
        if (widget.tournament != null) {
          _selectedTournamentId = widget.tournament!.id;
          _initializeScoreControllers(widget.tournament!);
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
                      var selectedTournament = availableTournaments.firstWhere(
                            (tournament) => tournament.id == newValue,
                        //orElse: () => null,
                      );
                      _scoreControllers.clear();
                      if (selectedTournament != null) {
                        _initializeScoreControllers(selectedTournament);
                      }
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
                        value: participant.id ?? participant.name,
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
                    onPressed: () {
                      // Logic to handle game addition
                    },
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
