import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'welcome_screen.dart';



const Color kPrimaryPurple = Color(0xFF715AFF);

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initSplash();
  }

  Future<void> _initSplash() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userData = prefs.getString('userData');
    print("token  $token");
    print("userData  $userData");

    if (!mounted) return;

    if (token != null && token.isNotEmpty && userData != null && userData.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Background image
          Positioned.fill(
            child: Image.asset(
              'assets/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // 🔹 Content overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryPurple),
                  strokeWidth: 3.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
