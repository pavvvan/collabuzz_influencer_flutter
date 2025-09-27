import 'package:flutter/material.dart';
import 'package:influencer_dashboard/screens/campaign_tabs_page.dart';
import 'package:influencer_dashboard/screens/home_screen.dart';
import 'package:influencer_dashboard/screens/profile_screen.dart';
import 'package:influencer_dashboard/screens/search_filter_page.dart';
import 'package:influencer_dashboard/screens/social_accounts_page.dart';
import 'package:influencer_dashboard/screens/welcome_screen.dart';

import 'notification_sceeen.dart';

const Color kPrimaryPurple = Color(0xFF671DD1);
const Color kYellowHighlight = Color(0xFFFF8A00);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    SearchFilterPage(),
    CampaignTabTogglePage(),
    SocialAccountsPage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _buildBottomBar(),
      ),
    );
  }

  Widget _buildTopBar() {
    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
        child: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 24,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
              child: _iconWithDot(Icons.notifications_none_rounded, unread: true),
            ),

            const SizedBox(width: 12),
            _iconWithDot(Icons.chat_bubble_outline_rounded, unread: true),
          ],
        ),
      ),
    );
  }

  Widget _iconWithDot(IconData icon, {bool unread = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
        if (unread)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Material(
      elevation: 0, // No default shadow
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -2), // Shadow at top of BottomNav
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0, // Remove built-in shadow
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontFamily: 'Nunito'),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Nunito'),
          selectedItemColor: const Color(0xFFFF9900),
          unselectedItemColor: Colors.grey,
          items: [
            _navItem(Icons.home, 'Home', 0),
            _navItem(Icons.search, 'Search', 1),
            _centeredCampaignItem(), // Or replace with normal
            _navItem(Icons.people_outline, 'Social', 3),
            _navItem(Icons.person_outline, 'Profile', 4),
          ],
        ),
      ),
    );
  }




  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        color: _selectedIndex == index ? kPrimaryPurple : Colors.grey,
      ),
      label: label,
    );
  }

  BottomNavigationBarItem _centeredCampaignItem() {
    return BottomNavigationBarItem(
      icon: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kYellowHighlight,
        ),
        child: Icon(
          Icons.campaign,
          color: Colors.white,
          size: 22,
        ),
      ),
      label: 'Campaign',
    );
  }
}
