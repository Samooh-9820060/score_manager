import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:score_manager/screens/SignIn.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:score_manager/screens/home_page.dart';
import 'config/bukDataEntry.dart';
import 'firebase_options.dart';
import 'config/app_mode.dart';
import 'models/UserProfile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // Capture platform errors (outside Flutter)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Check if the user is signed in
  User? user = FirebaseAuth.instance.currentUser;
  UserProfileSingleton().fetchUserProfile();

  runApp(MyApp(user: user, analytics: analytics));
}

class MyApp extends StatelessWidget {
  final User? user;
  final FirebaseAnalytics analytics;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);

  const MyApp({super.key, required this.user, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: isDebugMode,
      title: 'Game Score Logger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      navigatorObservers: <NavigatorObserver>[observer],
      home: user != null ? const HomeScreen() : const SignInScreen(),
    );
  }
}