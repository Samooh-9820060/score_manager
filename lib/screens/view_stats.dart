import 'package:flutter/material.dart';

import '../models/Tournament.dart';

class ViewStatsScreen extends StatefulWidget {
  final Tournament tournament;

  ViewStatsScreen({Key? key, required this.tournament}) : super(key: key);

  @override
  _ViewStatsScreenState createState() => _ViewStatsScreenState();
}

class _ViewStatsScreenState extends State<ViewStatsScreen> {
  Map<String, dynamic> participantScores = {};

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
          DataCell(Text(entry.key, style: const TextStyle(fontSize: 14))),
          DataCell(Text(entry.value.toString(), style: const TextStyle(fontSize: 14))),
          DataCell(Text(wins.toString(), style: const TextStyle(fontSize: 14))),
        ],
      );
    }).toList()
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tournament.name} Scores'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Data Table
              DataTable(
                columnSpacing: 10,
                dataRowHeight: 40,
                headingRowHeight: 48,
                headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
                headingTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                columns: columns,
                rows: rows,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
