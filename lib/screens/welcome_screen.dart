import 'package:flutter/material.dart';
import 'package:influencer_dashboard/screens/auth/signup_screen.dart';

import 'auth/login_screen.dart';
// Import these or your actual screen files
// import 'login_screen.dart';
// import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/welcome_logo.png",
      "heading": "Welcome to Collabuzz",
      "desc": "Connect, collaborate, and grow your influence."
    },
    {
      "image": "assets/ai.png",
      "heading": "Discover Brands",
      "desc": "Find new partnerships and expand your reach effortlessly."
    },
    {
      "image": "assets/welcome_logo.png",
      "heading": "Manage Campaigns",
      "desc": "Track and manage all your influencer campaigns in one place."
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 40),
            SizedBox(
              height: 500,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => Column(
                  children: [
                    Container(
                      height: 400,
                      width: double.infinity,
                      child: Image.asset(
                        _pages[index]["image"]!,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    SizedBox(height: 32),
                    Text(
                      _pages[index]["heading"]!,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _pages[index]["desc"]!,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) =>
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pageIndex == index ? Color(0xFF671DD1) : Colors.grey[300],
                    ),
                  ),
              ),
            ),
            SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF671DD1),
                    shape: StadiumBorder(),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignupScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF671DD1), width: 2),
                    shape: StadiumBorder(),
                  ),
                  child: Text(
                    'Create an account',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Color(0xFF671DD1),
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}