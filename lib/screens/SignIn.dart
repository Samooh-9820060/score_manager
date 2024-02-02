import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  Future<void> _signUp() async {
    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _usernameController.text.isEmpty) {
      _showErrorDialog("Name, Email and password cannot be empty");
      return;
    } else {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
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

          _showVerifyEmailSentDialog();
          _emailController.clear();
          _usernameController.clear();
          _passwordController.clear();
          _tabController.index = 0;

        } else {
          _showErrorDialog("An error occurred while registering.");
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Auth error
        _showErrorDialog(e.message ?? "An error occurred");
      } catch (e) {
        // Log the error
        print(e.toString());
        _showErrorDialog("An unexpected error occurred: ${e.toString()}");
      }
    }
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Your Email'),
        content: const Text('A verification email has been sent. Please check your email and verify your account. After verifying please sign in.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog("Email and password cannot be empty");
      return;
    } else {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        var user = userCredential.user;
        if (user != null && !user.emailVerified) {
          _showErrorDialog("Email is not verified. Please check your email to verify. We have again sent an email to verify");
          await user.sendEmailVerification();
          return;
        }

        print('signed in');
        //Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
      } on FirebaseAuthException catch (e) {
        // Handle error
        _showErrorDialog(e.message ?? "An error occurred");
      } catch (e) {
        // Handle other errors
        print(e.toString());
        _showErrorDialog("An unexpected error occurred: ${e.toString()}");
      }
    }
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Implement Google Sign-In functionality here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
            decoration: customInputDecoration('Username', Icons.supervised_user_circle),
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
