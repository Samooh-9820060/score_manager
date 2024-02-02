import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _buttonColorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _buttonColorAnimation = ColorTween(
      begin: Colors.lightBlue,
      end: Colors.teal,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  InputDecoration customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: Colors.blue, width: 2),
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    const FlutterLogo(size: 100.0),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _buttonColorAnimation,
                      builder: (context, child) {
                        return ElevatedButton(
                          onPressed: () {
                            // Implement Google Sign-In functionality here
                          },
                          child: const Text('Sign In with Google'),
                          style: ElevatedButton.styleFrom(
                            primary: _buttonColorAnimation.value,
                            onPrimary: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Additional interactive elements here
                    TextField(
                      decoration: customInputDecoration('Email', Icons.email),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      obscureText: true,
                      decoration: customInputDecoration('Password', Icons.lock),
                      keyboardType: TextInputType.visiblePassword,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Additional Button Functionality
                      },
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
