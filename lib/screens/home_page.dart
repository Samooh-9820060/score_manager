import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:score_manager/screens/SignIn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score_manager/screens/create_tournament.dart';
import 'package:score_manager/screens/profile_page.dart';
import 'package:score_manager/screens/tournament_page.dart';

enum FloatingActionButtonAction {
  createTournament,
  addScore,
}
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
    ProfilePage(),
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
      floatingActionButton: Container(
        height: 56.0, // Standard FAB height
        width: 56.0, // Standard FAB width
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).primaryColor, // Or any other color you prefer
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8.0,
              spreadRadius: 3.0,
            ),
          ],
        ),
        child: PopupMenuButton<FloatingActionButtonAction>(
          enableFeedback: true,
          offset: Offset(0, -140),
          onSelected: (FloatingActionButtonAction result) {
            switch (result) {
              case FloatingActionButtonAction.createTournament:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TournamentCreationForm()),
                );
                break;
              case FloatingActionButtonAction.addScore:
              // Navigate to Add Score page or perform action
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<FloatingActionButtonAction>>[
            const PopupMenuItem<FloatingActionButtonAction>(
              value: FloatingActionButtonAction.createTournament,
              child: ListTile(
                leading: Icon(Icons.create),
                title: Text('Create Tournament'),
              ),
            ),
            const PopupMenuItem<FloatingActionButtonAction>(
              value: FloatingActionButtonAction.addScore,
              child: ListTile(
                leading: Icon(Icons.add),
                title: Text('Add Score'),
              ),
            ),
          ],
          child: Icon(Icons.add, color: Colors.white),
          tooltip: 'Options',
        ),
      ),
    );
  }
}
