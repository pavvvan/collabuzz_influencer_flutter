import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todayNotifications = [
      {
        'title': 'Welcome to CollaBuzz! 🎉',
        'subtitle': 'Your influencer profile has been created. Complete your profile to get discovered by top brands.',
        'time': '5 Min',
        'color': Colors.blue[100],
        'iconColor': Colors.blue[600],
      },
      {
        'title': 'New Collaboration Tip',
        'subtitle': 'Add your Instagram & YouTube accounts to unlock personalized campaign recommendations.',
        'time': '20 Min',
        'color': Colors.purple[100],
        'iconColor': Colors.purple[600],
      },
      {
        'title': 'Boost Your Visibility 🚀',
        'subtitle': 'Upload a professional profile picture and highlight your top-performing posts to attract brands.',
        'time': '40 Min',
        'color': Colors.orange[100],
        'iconColor': Colors.orange[600],
      },
    ];

    final yesterdayNotifications = [
      {
        'title': 'Explore Barter Campaigns',
        'subtitle': 'Start with barter campaigns to receive free products and build your collaboration history.',
        'time': '3 Hours',
        'color': Colors.green[100],
        'iconColor': Colors.green[600],
      },
      {
        'title': 'Stay Active to Earn',
        'subtitle': 'Respond quickly to campaign invites and increase your chances of getting selected by brands.',
        'time': '6 Hours',
        'color': Colors.red[100],
        'iconColor': Colors.red[600],
      },
    ];


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            )),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Today"),
          const SizedBox(height: 8),
          ...todayNotifications.map((n) => _buildNotificationTile(n)).toList(),
          const SizedBox(height: 24),
          _buildSectionHeader("Yesterday"),
          const SizedBox(height: 8),
          ...yesterdayNotifications.map((n) => _buildNotificationTile(n)).toList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: n['color'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.notifications_active_outlined,
                color: n['iconColor'], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  n['subtitle'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            n['time'],
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
