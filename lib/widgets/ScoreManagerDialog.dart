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
});;
}
