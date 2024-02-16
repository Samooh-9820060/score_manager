import 'package:flutter/material.dart';

import '../models/Tournament.dart';
import '../services/TournamentService.dart';

class FinishTournamentWidget extends StatefulWidget {
  final Tournament tournament;
  FinishTournamentWidget({Key? key, required this.tournament}) : super(key: key);

  @override
  _FinishTournamentWidgetState createState() => _FinishTournamentWidgetState();
}

class _FinishTournamentWidgetState extends State<FinishTournamentWidget> {
  int? selectedWinnerIndex;

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<int>> dropdownItems = [];
    for (int i = 0; i < widget.tournament.participants.length; i++) {
      dropdownItems.add(DropdownMenuItem(
        value: i,
        child: Text(widget.tournament.participants[i].name),
      ));
    }

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          Text('Select Winner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          DropdownButton<int>(
            isExpanded: true,
            value: selectedWinnerIndex,
            items: dropdownItems,
            onChanged: (int? newValue) {
              setState(() {
                selectedWinnerIndex = newValue;
              });
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: selectedWinnerIndex != null
                ? () async {
              await TournamentService().finishTournament(
                  widget.tournament.id, selectedWinnerIndex!);
              Navigator.of(context).pop(); // Close the dialog
            }
                : null,
            child: Text('Finish Tournament'),
          ),
        ],
      ),
    );
  }
}
