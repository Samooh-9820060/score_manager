import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:score_manager/models/Tournament.dart';
import 'package:score_manager/widgets/ScoreManagerDialog.dart';

import '../models/Participants.dart';
import '../models/UserProfile.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
class TournamentCreationForm extends StatefulWidget {
  final Tournament? tournament;

  const TournamentCreationForm({Key? key, this.tournament}) : super(key: key);

  @override
  TournamentCreationFormState createState() => TournamentCreationFormState();
}

class TournamentCreationFormState extends State<TournamentCreationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _participantController = TextEditingController();
  List<Participant> _participants = [];
  String mode = 'Create';
  String _scoringMethod = 'direct';
  String _pointCalculationFrequency = 'Daily';
  List<int> _pointValues = List.filled(4, 0);

  List<UserProfile> _searchResults = []; // Update to use UserProfile
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    // Check if a tournament is provided for updating
    if (widget.tournament != null) {
      mode = 'Update';
      _nameController.text = widget.tournament!.name;
      // Check for null start date and format it
      if (widget.tournament!.startDate != null) {
        _startDateController.text =
            DateFormat('dd-MM-yyyy')
                .format(widget.tournament!.startDate!);
      } else {
        _startDateController.text = '';
      }

      // Check for null end date and format it
      if (widget.tournament!.endDate != null) {
        _endDateController.text =
            DateFormat('dd-MM-yyyy')
                .format(widget.tournament!.endDate!);
      } else {
        _endDateController.text = '';
      }
      _participants = widget.tournament!.participants;
      _scoringMethod = widget.tournament!.scoringMethod;
      _pointValues = widget.tournament!.pointValues;
    }
  }

  void _searchUser(String query) async {
    if (query.isNotEmpty) {
      setState(() => _isSearching = true);

      // Query the database for users
      List<UserProfile> results = await _queryDatabaseForUsers(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } else {
      setState(() => _searchResults.clear());
    }
  }

  Future<List<UserProfile>> _queryDatabaseForUsers(String query) async {
    try {
      // Query for matching usernames
      var usernameQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('allowTournamentAddition', isEqualTo: true)
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: '${query}z')
          .limit(5)
          .get();

      // Query for matching emails
      var emailQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('allowTournamentAddition', isEqualTo: true)
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: '${query}z')
          .limit(5)
          .get();

      // Combine and deduplicate the results
      Map<String, UserProfile> combinedResults = {};

      for (var doc in usernameQuerySnapshot.docs) {
        var data = doc.data();
        combinedResults[doc.id] = UserProfile(
          id: doc.id,
          name: data['username'],
          mail: data['email'],
          profileImageURL: data['profileImageUrl'],
        );
      }

      for (var doc in emailQuerySnapshot.docs) {
        if (!combinedResults.containsKey(doc.id)) {
          var data = doc.data();
          combinedResults[doc.id] = UserProfile(
            id: doc.id,
            name: data['username'],
            mail: data['email'],
            profileImageURL: data['profileImageUrl'],
          );
        }
      }


      // Remove already added participants from the results
      List<UserProfile> filteredResults = combinedResults.values
          .where((profile) => !_participants.any((p) => p.id == profile.id || p.name == profile.name))
          .toList();

      filteredResults.sort((a, b) => a.name.compareTo(b.name));
      return filteredResults.take(5).toList();

    } catch (e) {
      return [];
    }
  }



  InputDecoration customInputDecoration(String label, IconData icon, {bool isOptional = false}) {
    return InputDecoration(
      labelText: isOptional ? '$label (Optional)' : label,
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      initialDate = DateFormat('dd-MM-yyyy').parse(controller.text);
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000), // Adjust as needed
      lastDate: DateTime(2035), // Adjust as needed
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        controller.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$mode Tournament'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Tournament Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: customInputDecoration('Tournament Name', Icons.sports_esports),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name for the tournament';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _startDateController,
                  decoration: customInputDecoration('Start Date', Icons.date_range, isOptional: true),
                  onTap: () => _selectDate(context, _startDateController),
                  readOnly: true, // Prevents keyboard from appearing
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _endDateController,
                  decoration: customInputDecoration('End Date', Icons.date_range, isOptional: true),
                  onTap: () => _selectDate(context, _endDateController),
                  readOnly: true, // Prevents keyboard from appearing
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _showGameSettingsDialog(),
                    child: const Text('Configure Point Settings'),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _participantController,
                        decoration: customInputDecoration('Add Participants', Icons.person),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                      onPressed: () => _searchUser(_participantController.text),
                    ),
                  ],
                ),
                _buildSearchResults(),
                const SizedBox(height: 20),
                _buildParticipantList(),
                const SizedBox(height: 40),

                // Create Tournament Button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).secondaryHeaderColor,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        mode == 'Create' ? createTournament() : updateTournament();
                      }
                    },
                    child: Text('$mode Tournament'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGameSettingsDialog() {
    int numberOfPlayers = _pointValues.length;
    List<TextEditingController> pointControllers = List.generate(
      numberOfPlayers,
          (index) => TextEditingController(text: _pointValues[index].toString()),
    );

    String scoringMethod = _scoringMethod;
    String pointCalculationFrequency = 'Daily';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Point Settings'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    DropdownButton<String>(
                      value: scoringMethod,
                      onChanged: (String? newValue) {
                        setState(() {
                          scoringMethod = newValue!;
                        });
                      },
                      items: <String>['points', 'direct']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.capitalize()),
                        );
                      }).toList(),
                    ),
                    if (scoringMethod == 'points')
                      DropdownButton<String>(
                        value: pointCalculationFrequency,
                        onChanged: (String? newValue) {
                          setState(() {
                            pointCalculationFrequency = newValue!;
                          });
                        },
                        items: <String>['Daily', 'Monthly', 'Yearly']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      ...List.generate(numberOfPlayers, (index) {
                        return TextField(
                          controller: pointControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Points for Position ${index + 1}',
                          ),
                          keyboardType: TextInputType.number,
                        );
                      }),
                    const SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space the buttons
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 40), // Minimum button size
                          ),
                          child: const Text('Add'),
                          onPressed: () {
                            setState(() {
                              if (numberOfPlayers < 10) {
                                numberOfPlayers++;
                                pointControllers.add(TextEditingController());
                              }
                            });
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 40), // Minimum button size
                          ),
                          child: const Text('Remove'),
                          onPressed: () {
                            setState(() {
                              if (numberOfPlayers > 1) {
                                numberOfPlayers--;
                                pointControllers.removeLast();
                              }
                            });
                          },
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 40), // Minimum button size
                ),
                child: const Text('Save'),
                onPressed: () {
                  setState(() {
                    _scoringMethod = scoringMethod;
                    _pointValues = pointControllers.map((controller) {
                      return int.tryParse(controller.text) ?? 0;
                    }).toList();
                    _pointCalculationFrequency = pointCalculationFrequency;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        child: Center(
            child: CircularProgressIndicator()
        ),
      );
    }

    if (_participants.isNotEmpty) {
      //return SizedBox();
    }

    List<Widget> resultWidgets = _searchResults.isNotEmpty
        ? _searchResults.map((userProfile) {
      return ListTile(
        leading: userProfile.profileImageURL != null
            ? CircleAvatar(backgroundImage: NetworkImage(userProfile.profileImageURL!))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(userProfile.name),
        subtitle: userProfile.mail != null ? Text(userProfile.mail!) : null,
        onTap: () {
          _addParticipantFromSearch(userProfile);
        },
      );
    }).toList()
        : [];

    // Option to add a local user
    if (_participantController.text.isNotEmpty) {
      resultWidgets.add(ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_add)),
        title: Text('Add "${_participantController.text}" as a local user'),
        onTap: () {
          _addLocalParticipant(_participantController.text);
          _participantController.clear();
        },
      ));
    }

    return Column(children: resultWidgets);
  }

  void _addParticipantFromSearch(UserProfile userProfile) {
    if (!_participants.any((p) => p.id == userProfile.id)) {
      setState(() {
        _participants.add(Participant(
          id: userProfile.id,
          name: userProfile.name,
          isRegisteredUser: true,
          mail: userProfile.mail,
          profileImageURL: userProfile.profileImageURL,
        ));
        _searchResults.clear(); // Clear search results
        _participantController.clear();
        _isSearching = false; // Stop the search
      });
    } else {
      showInfoDialog('Error', 'Participant already added', false, context);
    }
  }

  void _addLocalParticipant(String name) {
    if (!_participants.any((p) => p.name == name)) {
      setState(() {
        _participants.add(Participant(name: name, isRegisteredUser: false));
        _searchResults.clear(); // Clear search results
        _participantController.clear();
        _isSearching = false; // Stop the search
      });
    } else {
      showInfoDialog('Error', 'Participant already added', false, context);
    }
  }

  Widget _buildParticipantList() {
    return ListView.builder(
      shrinkWrap: true, // Ensures the ListView only occupies the space it needs
      physics: const NeverScrollableScrollPhysics(), // Disables scrolling within the ListView
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        var participant = _participants[index];
        return ListTile(
          leading: participant.profileImageURL != null
              ? CircleAvatar(backgroundImage: NetworkImage(participant.profileImageURL!))
              : const CircleAvatar(child: Icon(Icons.person)),
          title: Text(participant.name),
          subtitle: participant.mail != null ? Text(participant.mail!) : null,
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editParticipant(participant, index),
          ),
        );
      },
    );
  }

  void _editParticipant(Participant participant, int index) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameController = TextEditingController(text: participant.name);
        TextEditingController searchController = TextEditingController();
        List<UserProfile> searchResults = [];
        UserProfile? selectedUserProfile;
        bool isSearching = false;

        return AlertDialog(
          title: const Text('Edit Participant'),
          content: StatefulBuilder(
            builder: (BuildContext innerContext, StateSetter setState) {
              void searchUser() async {
                String query = searchController.text.trim();
                if (query.isNotEmpty) {
                  setState(() => isSearching = true);
                  List<UserProfile> results = await _queryDatabaseForUsers(query);
                  setState(() {
                    searchResults = results;
                    isSearching = false;
                  });
                } else {
                  setState(() {
                    searchResults.clear();
                    selectedUserProfile = null;
                  });
                }
              }

              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search User',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: searchUser,
                        ),
                      ),
                    ),
                    if (isSearching)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Center(child: CircularProgressIndicator()))
                    else
                      ...searchResults.map((userProfile) {
                        bool isSelected = selectedUserProfile?.id == userProfile.id;
                        return ListTile(
                          tileColor: isSelected ? Colors.grey[300] : null, // Highlight selected item
                          leading: userProfile.profileImageURL != null
                              ? CircleAvatar(backgroundImage: NetworkImage(userProfile.profileImageURL!))
                              : const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(userProfile.name),
                          subtitle: userProfile.mail != null ? Text(userProfile.mail!) : null,
                          onTap: () {
                            setState(() {
                              selectedUserProfile = userProfile;
                              nameController.text = userProfile.name;
                              // Optionally update other participant details
                            });
                          },
                        );
                      }).toList(),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                bool isAppUser = selectedUserProfile != null;
                bool isLocalUser = searchController.text.trim().isNotEmpty && selectedUserProfile == null;

                Participant updatedParticipant = Participant(
                  id: isAppUser ? selectedUserProfile!.id : null, // Set to null for local users
                  name: isAppUser ? selectedUserProfile!.name : (isLocalUser ? searchController.text.trim() : nameController.text),
                  isRegisteredUser: isAppUser,
                  mail: isAppUser ? selectedUserProfile!.mail : null, // Set to null for local users
                  profileImageURL: isAppUser ? selectedUserProfile!.profileImageURL : null, // Set to null for local users
                );

                setState(() {
                  _participants[index] = updatedParticipant;
                });
                Navigator.of(context).pop();
              },
            ),

            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  _participants.removeAt(index);
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void createTournament() async {
    // Validate form fields
    if (_formKey.currentState!.validate()) {
      try {

        // Create a tournament object
        DateTime? startDate;
        DateTime? endDate;

        if (_startDateController.text.isNotEmpty) {
          startDate = DateFormat('dd-MM-yyyy').parse(_startDateController.text);
        }
        if (_endDateController.text.isNotEmpty) {
          endDate = DateFormat('dd-MM-yyyy').parse(_endDateController.text);
        }

        // Extract non-null user ids from participants
        List<String> viewableUsers = _participants
            .where((participant) => participant.id != null && participant.isRegisteredUser)
            .map((participant) => participant.id!)
            .toList();

        // Create a tournament object
        Tournament newTournament = Tournament(
          id: FirebaseFirestore.instance.collection('tournaments').doc().id, // Generate unique ID
          name: _nameController.text.trim(),
          startDate: startDate,
          endDate: endDate,
          participants: _participants,
          scoringMethod: _scoringMethod,
          pointCalculationFrequency: _pointCalculationFrequency,
          pointValues: _pointValues,
          createdDate: DateTime.now(),
          createdBy: FirebaseAuth.instance.currentUser!.uid,
          viewTournament: viewableUsers,
        );

        // Convert the tournament object to a Map
        Map<String, dynamic> tournamentData = {
          'id': newTournament.id,
          'name': newTournament.name,
          'startDate': newTournament.startDate?.toIso8601String(),
          'endDate': newTournament.endDate?.toIso8601String(),
          'participants': newTournament.participants.map((p) => p.toMap()).toList(),
          'scoringMethod': newTournament.scoringMethod,
          'pointCalculationFrequency': newTournament.pointCalculationFrequency,
          'pointValues': newTournament.pointValues,
          'createdDate': newTournament.createdDate.toIso8601String(),
          'createdBy': newTournament.createdBy,
          'viewTournament': newTournament.viewTournament,
        };

        // Save to Firestore
        await FirebaseFirestore.instance.collection('tournaments').doc(newTournament.id).set(tournamentData);

        showInfoDialog('Create Tournament', 'Tournament created successfully!', true, context);
      } catch (e) {
        showInfoDialog('Create Tournament', 'Error creating tournament: $e', false, context);
      }
    } else {
    }
  }

  void updateTournament() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create a tournament object
        DateTime? startDate;
        DateTime? endDate;

        if (_startDateController.text.isNotEmpty) {
          startDate = DateFormat('dd-MM-yyyy').parse(_startDateController.text);
        }
        if (_endDateController.text.isNotEmpty) {
          endDate = DateFormat('dd-MM-yyyy').parse(_endDateController.text);
        }

        // Extract non-null user ids from participants
        List<String> viewableUsers = _participants
            .where((participant) => participant.id != null && participant.isRegisteredUser)
            .map((participant) => participant.id!)
            .toList();

        Tournament currentTournament = Tournament(
          id: widget.tournament!.id, // Use existing ID
          name: _nameController.text.trim(),
          startDate: startDate,
          endDate: endDate,
          participants: _participants,
          scoringMethod: _scoringMethod,
          pointCalculationFrequency: _pointCalculationFrequency,
          pointValues: _pointValues,
          createdDate: widget.tournament!.createdDate, // Use existing createdDate
          createdBy: widget.tournament!.createdBy,
          viewTournament: viewableUsers,
        );

        // Convert the tournament object to a Map
        Map<String, dynamic> tournamentData = {
          'id': currentTournament.id,
          'name': currentTournament.name,
          'startDate': currentTournament.startDate?.toIso8601String(),
          'endDate': currentTournament.endDate?.toIso8601String(),
          'participants': currentTournament.participants.map((p) => p.toMap()).toList(),
          'scoringMethod': currentTournament.scoringMethod,
          'pointCalculationFrequency': currentTournament.pointCalculationFrequency,
          'pointValues': currentTournament.pointValues,
          'createdDate': currentTournament.createdDate.toIso8601String(),
          'createdBy': currentTournament.createdBy,
          'viewTournament': currentTournament.viewTournament,
        };

        // Update Firestore document
        await FirebaseFirestore.instance.collection('tournaments').doc(currentTournament.id).update(tournamentData);

        showInfoDialog('Update Tournament', 'Tournament updated successfully!', true, context);
      } catch (e) {
        showInfoDialog('Update Tournament', 'Error updating tournament: $e', false, context);
      }
    }
  }
}
