import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/Tournament.dart';
import '../widgets/ScoreManagerDialog.dart';

class InsertOtherScoresScreen extends StatefulWidget {
  final Tournament? tournament;
  final Object? manualScoreEntry;

  const InsertOtherScoresScreen(
      {super.key, this.tournament, this.manualScoreEntry});

  @override
  _InsertOtherScoresScreenState createState() =>
      _InsertOtherScoresScreenState();
}

class _InsertOtherScoresScreenState extends State<InsertOtherScoresScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedType;
  String? _selectedParticipant;
  String? _selectedParticipantIndex;
  bool updateData = false;
  TextEditingController _reasonController = TextEditingController();
  TextEditingController _valueController = TextEditingController();
  TextEditingController _dateTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType =
        getDropdownItems().first; // Set the first dropdown item as selected
    _dateTimeController.text =
        DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
    if (widget.tournament?.participants.isNotEmpty == true) {
      _selectedParticipantIndex = widget.tournament?.participants.first.id;
    }

    if (widget.manualScoreEntry != null) {
      _loadManualScoreEntry();
      updateData = true;
    }
  }

  void _loadManualScoreEntry() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    var tournamentId = widget.tournament?.id;

    var snapshot = await firestore
        .collection('manualScoreEntries')
        .doc(tournamentId)
        .get();
    var data = snapshot.data();

    if (data != null && data.containsKey(widget.manualScoreEntry)) {
      var entryData = data[widget.manualScoreEntry] as Map<String, dynamic>;
      setState(() {
        _selectedType = entryData['typeToAdd'];
        _valueController.text = entryData['value'];
        _reasonController.text = entryData['reason'];
        _dateTimeController.text = entryData['dateTime'];

        int? participantIndex = entryData['participantIndex'];
        if (participantIndex != null &&
            widget.tournament!.participants.length > participantIndex) {
          _selectedParticipant =
              widget.tournament!.participants[participantIndex].name;
        }
      });
    }
  }

  List<String> getDropdownItems() {
    List<String> items = ['Points', 'Score', 'Wins'];
    if (widget.tournament?.scoringMethod == 'direct') {
      items.remove('Points');
    }
    return items;
  }


  Future<void> _deleteEntry(BuildContext context) async {
    var tournamentId = widget.tournament?.id;
    var manualScoreEntryKey = widget.manualScoreEntry;

    if (tournamentId != null && manualScoreEntryKey != null) {
      DocumentReference docRef = FirebaseFirestore.instance.collection('manualScoreEntries').doc(tournamentId);

      await docRef.update({manualScoreEntryKey: FieldValue.delete()})
          .then((_) {
        showInfoDialog('Update Entry', 'Entry has been deleted', true, context);
        Navigator.of(context).pop();
      })
          .catchError((error) {
        showInfoDialog('Error', 'Failed to delete entry: $error', false, context);
      });
    } else {
      showInfoDialog('Error', 'Tournament ID or Entry Key is null', false, context);
    }
  }




  void _addDataToFirestore() async {
    if (_valueController.text.isEmpty || _valueController.text.length == 0) {
      showInfoDialog('Error', 'Invalid Value selected', false, context);
      return;
    }

    if (_reasonController.text.isEmpty || _reasonController.text.length < 5) {
      showInfoDialog('Error', 'Reason cannot be empty', false, context);
      return;
    }
    if (_formKey.currentState!.validate()) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Find the index of the selected participant
      int? selectedParticipantIndex =
          widget.tournament?.participants.indexWhere(
        (p) => p.name == _selectedParticipant,
      );

      // Proceed only if a valid participant is selected
      if (selectedParticipantIndex != null && selectedParticipantIndex != -1) {
        Map<String, dynamic> data = {
          'typeToAdd': _selectedType,
          'participantIndex': selectedParticipantIndex,
          'value': _valueController.text,
          'reason': _reasonController.text,
          'dateTime': _dateTimeController.text,
          'insertedBy': FirebaseAuth.instance.currentUser?.uid,
          'insertedDate': DateTime.now().toIso8601String(),
        };

        DocumentReference docRef = firestore.collection('manualScoreEntries').doc(widget.tournament?.id);

        if (widget.manualScoreEntry == null) {
          // Add new entry
          String safeKey = "${DateTime.now().millisecondsSinceEpoch}";
          await docRef.set({safeKey: data}, SetOptions(merge: true))
              .then((_) => showInfoDialog('Success', 'Data added successfully', true, context));
        } else {
          // Update existing entry
          await docRef.update({widget.manualScoreEntry!: data})
              .then((_) => showInfoDialog('Success', 'Data updated successfully', true, context))
              .catchError((error) => showInfoDialog('Error', 'Failed to update data: $error', false, context));
        }
      } else {
        // Handle the case when no valid participant is selected
        showInfoDialog('Error', 'Invalid participant selected', false, context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> dropdownItems = getDropdownItems();
    List<String> participantNames =
        widget.tournament?.participants.map((p) => p.name).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: updateData
            ? Text('Update Other Scores/Wins')
            : Text('Insert Other Scores/Wins'),
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
                  value: _selectedType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                  items: dropdownItems
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Select Type to Add',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedParticipant,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedParticipant = newValue;
                    });
                  },
                  items: participantNames
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Select Participant',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Value',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for Adding',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _dateTimeController,
                  decoration: InputDecoration(
                    labelText: 'Date and Time',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _selectDateTime(context),
                    ),
                  ),
                  readOnly: true,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: ElevatedButton(
                        onPressed: _addDataToFirestore,
                        child:
                            updateData ? Text('Update Data') : Text('Add Data'),
                      ),
                    ),
                    if (updateData) ...{
                      SizedBox(width: 20,),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => _deleteEntry(context),
                          child: const Text('Delete Entry'),
                        ),
                      ),
                    }
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    DateTime initialDateTime;
    if (_dateTimeController.text.isNotEmpty) {
      // Parse the current value of the controller into a DateTime object
      initialDateTime =
          DateFormat('yyyy-MM-dd – kk:mm').parse(_dateTimeController.text);
    } else {
      // If the controller is empty, use the current date and time
      initialDateTime = DateTime.now();
    }

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime(initialDateTime.year - 5),
      lastDate: DateTime(initialDateTime.year + 5),
    );

    if (selectedDate != null) {
      // Extract the time part from the initialDateTime
      TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDateTime);

      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (selectedTime != null) {
        // Combine the selected date and time into a single DateTime object
        DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        // Update the controller with the selected date and time
        _dateTimeController.text =
            DateFormat('yyyy-MM-dd – kk:mm').format(selectedDateTime);
      }
    }
  }
}
