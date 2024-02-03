import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:score_manager/screens/SignIn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score_manager/screens/create_tournament.dart';
import 'package:score_manager/screens/tournament_page.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? username;
  var _bottomNavIndex = 0;
  late PageController _pageController;

  // List of page titles
  final List<String> _pageTitles = [
    'Scores',
    'Tournaments',
    'Profile',
  ];

  final List<Widget> _pages = [
    SignInScreen(),
    TournamentListPage(),
    TournamentCreationForm(),
  ];

  @override
  void initState() {
    super.initState();
    fetchUsername();
    _pageController = PageController(initialPage: _bottomNavIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  Future<void> fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (querySnapshot.exists) {
        setState(() {
          username = querySnapshot.data()?['username'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_bottomNavIndex]),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignInScreen()));
            },
          ),
        ],
      ),
      body:  PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.score), label: 'Scores'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: 'Tournaments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _bottomNavIndex,
        onTap: _onTabTapped,
        showUnselectedLabels: false,
      ),
    );
  }
}
