import 'package:flutter/material.dart';
import '../../services/dart/auth_services.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool emailNotifications = false;
  bool pushNotifications = false;
  bool loading = true;

  final Color purple = const Color(0xFF671DD1);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final authService = AuthServices();
    final res = await authService.getProfile();
    if (res != null && res['profileData'] != null) {
      final profile = res['profileData'];
      setState(() {
        emailNotifications = profile['emailNotifications'] ?? false;
        pushNotifications = profile['pushNotifications'] ?? false;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    final authService = AuthServices();
    await authService.updateProfile({key: value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildToggleCard(
              title: "Email Notifications",
              subtitle: "Get updates and offers via email.",
              value: emailNotifications,
              onChanged: (val) {
                setState(() => emailNotifications = val);
                _updatePreference("emailNotifications", val);
              },
            ),
            const SizedBox(height: 16),
            _buildToggleCard(
              title: "Push Notifications",
              subtitle: "Receive instant alerts on your phone.",
              value: pushNotifications,
              onChanged: (val) {
                setState(() => pushNotifications = val);
                _updatePreference("pushNotifications", val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: purple,
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}
