import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:score_manager/widgets/ScoreManagerDialog.dart';

class ContactUsPage extends StatefulWidget {
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? _selectedEmailOption;
  List<String> emailOptions = [];

  @override
  void initState() {
    super.initState();
    _initializeEmailOptions();
  }

  void _initializeEmailOptions() {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    emailOptions = ['Anonymous', if (userEmail != null) userEmail];
    _selectedEmailOption = userEmail ?? 'Anonymous';
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('feedback').add({
        'uid': _selectedEmailOption == 'Anonymous' ? '' : FirebaseAuth.instance.currentUser?.uid,
        'subject': _subjectController.text,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      showInfoDialog('Feedback Submitted', 'Your feedback has been submitted', true, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Us'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  value: _selectedEmailOption,
                  decoration: InputDecoration(
                    labelText: 'Your Email',
                    icon: Icon(Icons.email),
                  ),
                  items: emailOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedEmailOption = newValue;
                    });
                  },
                ),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    icon: Icon(Icons.subject),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    icon: Icon(Icons.message),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your message';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitFeedback,
                    child: Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
