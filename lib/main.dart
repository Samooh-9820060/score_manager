import 'package:flutter/material.dart';
import 'package:score_manager/screens/SignIn.dart';

import 'config/app_mode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: isDebugMode,
      title: 'Game Score Logger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SignInScreen(),
    );
  }
}