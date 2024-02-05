import 'package:flutter/material.dart';

void showInfoDialog(String title, String message, bool goBackTwice, BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
          },
          child: const Text('Okay'),
        ),
      ],
    ),
  ).then((_) {
    goBackTwice ? Navigator.of(context).pop() : null;
});
}

Future<bool> showConfirmDialog(String title, String content, BuildContext context) async {
  return await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(false), // Return false on cancel
        ),
        TextButton(
          child: Text('Confirm'),
          onPressed: () => Navigator.of(context).pop(true), // Return true on confirm
        ),
      ],
    ),
  ) ?? false; // Return false if the dialog is dismissed
}

