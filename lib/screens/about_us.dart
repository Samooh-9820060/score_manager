import 'package:flutter/material.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  AboutUsPageState createState() => AboutUsPageState();
}

class AboutUsPageState extends State<AboutUsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 20).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Us'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 40),
              SizedBox(height: _animation.value),
              CircleAvatar(
                radius: 150, // Adjust the radius as needed
                backgroundImage: AssetImage('assets/icons/app_icon.png'), // Replace with your image path
              ),
              Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'We are passionate about creating amazing apps that make a difference. Our team is dedicated to delivering quality and innovation in every project.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              // Add more content here like team section, timeline, etc.
            ],
          ),
        ),
      ),
    );
  }
}
