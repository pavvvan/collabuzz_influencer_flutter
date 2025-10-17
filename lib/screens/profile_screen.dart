import 'package:flutter/material.dart';
import 'package:influencer_dashboard/screens/auth/login_screen.dart';
import 'package:influencer_dashboard/screens/wallet_page.dart';
import 'package:influencer_dashboard/screens/webview.dart';
import 'package:influencer_dashboard/screens/welcome_screen.dart';
import 'package:influencer_dashboard/services/dart/auth_services.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth/edit_profile_page.dart';
import 'billing_address_page.dart';
import 'notification_settings_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) =>  LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _fetchProfile() async {
    final authService = AuthServices();
    final res = await authService.getProfile();
    if (res != null && res['profileData'] != null) {
      setState(() {
        profile = res;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  void _openWebView(BuildContext context, String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewScreen(title: title, url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileData = profile?['profileData'];
    final percent = profile?['profileCompletionPercentage'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
          ? const Center(child: Text("Failed to load profile"))
          : SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildProfileCard(profileData, percent),
            const SizedBox(height: 16),
            _buildSectionButton("Influencer Profile", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            }),
            const SizedBox(height: 20),
            _sectionHeader('Payments'),
            _listTile('Billing Address', () {Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BillingAddressPage()),
            );
            }),
            _listTile('Wallet', () {Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletPage()),
            );}),
            _divider(),
            _sectionHeader('Support'),
            _listTile('Faq', () {
              _openWebView(context, 'FAQ', 'https://collabuzz.com/faq.html');
            }),
            _listTile('Contact Us', () {
              _openWebView(context, 'Contact Us', 'https://collabuzz.com/contact.html');
            }),
            _divider(),
            _sectionHeader('Settings'),
            _listTile('Notifications', () {Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
            );
            }),
            _listTile('Contact Us', () {
              _openWebView(context, 'Contact Us', 'https://collabuzz.com/contact.html');
            }),
            _divider(),
            _sectionHeader('Legal'),
            _listTile('Privacy Policy', () {
              _openWebView(context, 'Privacy Policy', 'https://collabuzz.com/privacy.html');
            }),
            _listTile('Terms & Conditions', () {
              _openWebView(context, 'Terms & Conditions', 'https://collabuzz.com/terms.html');
            }),
            _divider(),
            _sectionHeader('Account'),
            _listTile('Delete My Account', () {
              _openWebView(context, 'Data Deletion', 'https://collabuzz.com/contact.html');
            }),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _logout(context),
              child: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFF671DD1), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Text('App version 1.1.1',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

  }

  Widget _sectionHeader(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF671DD1),
        ),
      ),
    );
  }

  Widget _listTile(String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _divider() {
    return const Divider(
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey,
      height: 20,
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profileData, int percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                 CircleAvatar(
                  radius: 40,
                  backgroundImage: profileData['profileImage'] != null && profileData['profileImage'].toString().isNotEmpty
                      ? NetworkImage(profileData['profileImage'])
                      : const AssetImage('assets/avatar.png') as ImageProvider,
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profileData['influencerName'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(profileData['phone'] ?? '', style: const TextStyle(fontSize: 14)),
                  Text(profileData['email'] ?? '', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSectionButton(String title, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
          shadowColor: Colors.black12,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

}
