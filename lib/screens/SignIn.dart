import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../widgets/ScoreManagerDialog.dart';
import 'home_page.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<bool> _checkUsernameExists(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _signUp() async {
    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      showInfoDialog(
          "Error", "Name, Email and password cannot be empty", context);
      return;
    } else if (username.length <= 5) {
      showInfoDialog(
          "Error", "Username must be longer than 5 characters", context);
      return;
    }

    var usernameExists = await _checkUsernameExists(username);
    if (usernameExists) {
      showInfoDialog("Error",
          "Username already exists, please choose another one", context);
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'username': username,
        'created': DateTime.now(),
      });

      final User? user = userCredential.user;
      // Send verification email
      if (user != null) {
        await user.sendEmailVerification();

        showInfoDialog(
            'Verify Your Email',
            'A verification email has been sent. Please check your email and verify your account. After verifying please sign in.',
            context);
        _emailController.clear();
        _usernameController.clear();
        _passwordController.clear();
        _tabController.index = 0;
      } else {
        showInfoDialog(
            "Error", "An error occurred while registering.", context);
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth error
      showInfoDialog("Error", e.message ?? "An error occurred", context);
    } catch (e) {
      // Log the error
      print(e.toString());
      showInfoDialog(
          "Error", "An unexpected error occurred: ${e.toString()}", context);
    }
  }

  Future<void> _signIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showInfoDialog("Error", "Email and password cannot be empty", context);
      return;
    } else {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        var user = userCredential.user;
        if (user != null && !user.emailVerified) {
          ;
          showInfoDialog(
              "Error",
              "Email is not verified. Please check your email to verify. We have again sent an email to verify",
              context);
          await user.sendEmailVerification();
          return;
        }

        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
      } on FirebaseAuthException catch (e) {
        // Handle error
        showInfoDialog("Error", e.message ?? "An error occurred", context);
      } catch (e) {
        // Handle other errors
        print(e.toString());
        showInfoDialog(
            "Error", "An unexpected error occurred: ${e.toString()}", context);
      }
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null)
        return null; // User cancelled the Google Sign-In process

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check Firestore for user details
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists || !userDoc.data()!.containsKey('username')) {
          // Prompt for additional user information
          bool usernameSet = await promptForAdditionalUserInfo(user);
          if (!usernameSet) {
            await FirebaseAuth.instance
                .signOut(); // Sign out if user details are not set
            return null;
          }
        }
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
    }
  }

  Future<bool> promptForAdditionalUserInfo(User? user) async {
    String username = '';
    bool usernameSet = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Username'),
          content: TextField(
            onChanged: (value) => username = value.trim(),
            decoration: const InputDecoration(hintText: "Username"),
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('Submit'),
                onPressed: () async {
                  if (username.isEmpty || username.length <= 5) {
                    showInfoDialog(
                        "Error", "Username must be longer than 5 characters", context);
                    return;
                  }

                  var usernameExists = await _checkUsernameExists(username);
                  if (usernameExists) {
                    showInfoDialog("Error",
                        "Username already exists, please choose another one", context);
                    return;
                  }
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .set({
                    'email': user?.email,
                    'username': username,
                    'created': DateTime.now(),
                  });
                  usernameSet = true;
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );

    return usernameSet;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 20),
                  ClipOval(
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 100.0,
                      height: 100.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            User? user = await signInWithGoogle();
                            setState(() => _isLoading = false);
                            if (user != null) {
                              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
                            } else {
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          child: const Text(
                            'Sign In with Google',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                  SizedBox(
                    // Set a specific height or make it flexible as per your design needs
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        buildLoginForm(context),
                        buildSignUpForm(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLoginForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _emailController,
            decoration: customInputDecoration('Email', Icons.email),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: customInputDecoration('Password', Icons.lock),
            keyboardType: TextInputType.visiblePassword,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _signIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () async {
              String email = _emailController.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  showInfoDialog(
                      'Reset Password',
                      'Instructions to reset password have been sent to $email. (If this email is signed in from)',
                      context);
                } catch (e) {
                  // Handle the error and show a dialog
                  showInfoDialog(
                      'Error', 'An error occurred: ${e.toString()}', context);
                }
              } else {
                // Prompt the user to enter a valid email
                showInfoDialog(
                    'Error', 'Please enter a valid email address', context);
              }
            },
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: Colors.blue, // Adjust the color to fit your theme
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildSignUpForm(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _emailController,
            decoration: customInputDecoration('Email', Icons.email),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameController,
            decoration:
                customInputDecoration('Username', Icons.supervised_user_circle),
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: customInputDecoration('Password', Icons.lock),
            keyboardType: TextInputType.visiblePassword,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
