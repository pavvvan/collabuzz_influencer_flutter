import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:influencer_dashboard/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brand Dashboard',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // ✅ Force portrait-style layout on web
        if (kIsWeb) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final double screenHeight = constraints.maxHeight;
              final double screenWidth = constraints.maxWidth;

              return Scaffold(
                backgroundColor: Colors.white, // full white, no margin/shadow
                body: Center(
                  child: Container(
                    // fixed portrait width but centered
                    width: screenWidth > 480 ? 420 : screenWidth,
                    height: screenHeight,
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.center,
                        maxWidth: 420, // maintain portrait width cap
                        minWidth: 0,
                        child: SizedBox(
                          width: screenWidth > 420 ? 420 : screenWidth,
                          height: screenHeight,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        // ✅ Normal behavior for mobile/tablet
        return child!;
      },
      home: const SplashScreen(),
    );
  }
}
