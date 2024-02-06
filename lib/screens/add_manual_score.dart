import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/Participants.dart';
import '../models/Tournament.dart';
import '../widgets/ScoreManagerDialog.dart';

class InsertOtherScoresScreen extends StatefulWidget {
  final Tournament? tournament;

  const InsertOtherScoresScreen({super.key, this.tournament});

  @override
  _InsertOtherScoresScreenState createState() => _InsertOtherScoresScreenState();
}

class _InsertOtherScoresScreenState extends State<InsertOtherScoresScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedType;
  String? _selectedParticipant;
  String? _selectedParticipantIndex;
  TextEditingController _reasonController = TextEditingController();
  TextEditingController _valueController = TextEditingController();
  TextEditingController _dateTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = getDropdownItems().first; // Set the first dropdown item as selected
    _dateTimeController.text = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
    if (widget.tournament?.participants.isNotEmpty == true) {
      _selectedParticipantIndex = widget.tournament?.participants.first.id;
    }
  }

  List<String> getDropdownItems() {
    List<String> items = ['Points', 'Score', 'Wins'];
    if (widget.tournament?.scoringMethod == 'direct') {
      items.remove('Points');
    }
    return items;
  }

  void _addDataToFirestore() async {
    if (_valueController.text.isEmpty || _valueController.text.length == 0) {
      showInfoDialog('Error', 'Invalid Value selected', false, context);
      return;
    }

    if (_reasonController.text.isEmpty || _reasonController.text.length > 5) {
      showInfoDialog('Error', 'Reason cannot be empty', false, context);
      return;
    }
    if (_formKey.currentState!.validate()) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Find the index of the selected participant
      int? selectedParticipantIndex = widget.tournament?.participants.indexWhere(
            (p) => p.name == _selectedParticipant,
      );

      // Proceed only if a valid participant is selected
      if (selectedParticipantIndex != null && selectedParticipantIndex != -1) {
        Map<String, dynamic> data = {
          'typeToAdd': _selectedType,
          'participantIndex': selectedParticipantIndex, // Store the participant index
          'value': _valueController.text,
          'reason': _reasonController.text,
          'dateTime': _dateTimeController.text,
          'insertedBy': FirebaseAuth.instance.currentUser?.uid,
          'insertedDate': DateTime.now().toIso8601String(),
        };

        await firestore
            .collection('manualScoreEntries')
            .doc(widget.tournament?.id)
            .set({DateTime.now().toIso8601String(): data}, SetOptions(merge: true))
            .then((_) {
          showInfoDialog('Success', 'Data added successfully', false, context);
        })
            .catchError((error) {
          showInfoDialog('Error', 'Failed to add data: $error', false, context);
        });
      } else {
        // Handle the case when no valid participant is selected
        showInfoDialog('Error', 'Invalid participant selected', false, context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> dropdownItems = getDropdownItems();
    List<String> participantNames = widget.tournament?.participants.map((p) => p.name).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Insert Other Scores/Wins'),
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
                  items: dropdownItems.map<DropdownMenuItem<String>>((String value) {
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
                  items: participantNames.map<DropdownMenuItem<String>>((String value) {
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
                Center(
                  child: ElevatedButton(
                    onPressed: _addDataToFirestore,
                    child: Text('Add Data'),
                  ),
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
      initialDateTime = DateFormat('yyyy-MM-dd – kk:mm').parse(_dateTimeController.text);
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
        _dateTimeController.text = DateFormat('yyyy-MM-dd – kk:mm').format(selectedDateTime);
      }
    }
  }
}
