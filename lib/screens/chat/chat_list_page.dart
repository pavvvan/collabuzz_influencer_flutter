import 'package:flutter/material.dart';
import '../../services/dart/campaign_service.dart';
import '../../widgets/empty_campaign_placeholder.dart';
import 'influencer_chat_dialog.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final result = await CampaignService().getChatList();
      setState(() {
        chats = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading chats: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.8,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chats.isEmpty
          ? const EmptyCampaignPlaceholder(
        icon: Icons.chat_bubble_outline_rounded,
        title: "No Chats Yet",
        subtitle:
        "You haven’t started any conversations.\nYour chats with brands will appear here.",
      )
          : RefreshIndicator(
        onRefresh: _fetchChats,
        child: ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey[200],
                backgroundImage: _getValidImage(chat['campaignImage']),
                child: (chat['campaignImage'] == null ||
                    chat['campaignImage'].toString().isEmpty)
                    ? const Icon(Icons.storefront_outlined,
                    color: Colors.grey, size: 26)
                    : null,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['partnerName'] ?? 'Unknown Brand',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat['campaignName'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  chat['lastMessage'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              trailing: Text(
                _formatTime(chat['lastMessageTime']),
                style:
                const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InfluencerChatDialog(
                      campaignId: chat['campaignId'] ?? '',
                      brandName: chat['partnerName'] ?? '',
                      brandImage: chat['campaignImage'] ?? '',
                      brandBio: chat['campaignName'] ?? '',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Safely validate image URL before loading
  ImageProvider? _getValidImage(dynamic url) {
    if (url == null) return null;
    final String imageUrl = url.toString().trim();
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) return null;
    return NetworkImage(imageUrl);
  }

  /// Format time (HH:mm if today, else dd/MM/yyyy)
  String _formatTime(String? time) {
    if (time == null) return '';
    final date = DateTime.tryParse(time);
    if (date == null) return '';
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "${date.day}/${date.month}/${date.year}";
  }
}
