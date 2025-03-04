import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:score_manager/screens/SignIn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score_manager/screens/about_us.dart';
import 'package:score_manager/screens/contact_us.dart';
import 'package:score_manager/screens/create_tournament.dart';
import 'package:score_manager/screens/game_form.dart';
import 'package:score_manager/screens/profile_page.dart';
import 'package:score_manager/screens/scores_page.dart';
import 'package:score_manager/screens/tournament_page.dart';

enum FloatingActionButtonAction {
  createTournament,
  addGame,
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
    ScoresPage(),
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

  void _handleFabPressed() {
    print(_bottomNavIndex);
    switch (_bottomNavIndex) {
      case 0:
        // Action for first tab
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddGameForm()),
        );
        break;
      case 1:
        // Action for second tab
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TournamentCreationForm()),
        );
        break;
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
          /*IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignInScreen()));
            },
          ),*/
        ],
      ),
      body: PageView(
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
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_tennis), label: 'Tournaments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _bottomNavIndex,
        onTap: _onTabTapped,
        showUnselectedLabels: false,
      ),
      floatingActionButton: _bottomNavIndex > 1
          ? FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 8.0,
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
              case FloatingActionButtonAction.addGame:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddGameForm()),
                );
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
              value: FloatingActionButtonAction.addGame,
              child: ListTile(
                leading: Icon(Icons.add),
                title: Text('Add Game'),
              ),
            ),
          ],
          child: Icon(Icons.add, color: Colors.white),
          tooltip: 'Options',
        ),
        onPressed: () {}, // Keep this empty since PopupMenuButton handles the interaction
      )
          : FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 8.0,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _handleFabPressed,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AutoSizeText(
                    'Welcome,',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                    maxLines: 1,
                  ),
                  AutoSizeText(
                    '$username',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_phone),
              title: const Text('Contact Us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactUsPage()),
                );
              },
            ),
            /*ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Handle Settings Navigation
              },
            ),*/
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn().signOut();
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SignInScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
