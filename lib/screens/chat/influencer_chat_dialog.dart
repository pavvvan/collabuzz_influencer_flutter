import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/dart/campaign_service.dart';
import '../../services/dart/socket_service.dart';


class InfluencerChatDialog extends StatefulWidget {
  final String brandName;
  final String brandImage;
  final String brandBio;
  final String campaignId;

  const InfluencerChatDialog({
    super.key,
    required this.brandName,
    required this.brandImage,
    required this.brandBio,
    required this.campaignId,
  });

  @override
  State<InfluencerChatDialog> createState() => _InfluencerChatDialogState();
}

class _InfluencerChatDialogState extends State<InfluencerChatDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SocketService _socketService = SocketService();
  final FocusNode _focusNode = FocusNode();

  String? _chatId;
  List<Map<String, dynamic>> messages = [];
  late AnimationController _marqueeController;

  @override
  void initState() {
    super.initState();

    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Request focus on input
    Future.delayed(const Duration(milliseconds: 300), () => _focusNode.requestFocus());

    _initChat();
  }

  Future<void> _initChat() async {
    final _campaignService = CampaignService();
    // 1️⃣ Open chat
    final prefs = await SharedPreferences.getInstance();
    final influencerId = prefs.getString('userId'); // Store userId at login
    final token = prefs.getString('token');
    print("widget.campaignId");
    print(widget.campaignId);

    final chatId = await _campaignService.openChat(
      campaignId: widget.campaignId,
      influencerId: influencerId!,
    );

    if (chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open chat')),
      );
      Navigator.pop(context);
      return;
    }

    _chatId = chatId;

    print("ChatId $chatId");

    // 2️⃣ Connect socket
    if (token != null) {
      _socketService.connect(token);
      _socketService.joinChat(_chatId!);
    }

    // 3️⃣ Listen for messages
    _socketService.listenMessages((msg) {
      setState(() => messages.add(Map<String, dynamic>.from(msg)));
      _scrollToBottom();
    });

    // 4️⃣ Fetch chat history
    final history = await _campaignService.getChatMessages(chatId: _chatId!);
    setState(() {
      messages.clear();
      messages.addAll(history);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null) return;

    _socketService.sendMessage(_chatId!, text);

    // ✅ Do not add locally (socket will emit)
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isInfluencer = (msg["senderRole"] ?? msg["sender"]) == "influencer";
    return Align(
      alignment: isInfluencer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isInfluencer ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg["message"] ?? msg["text"] ?? '',
          style: TextStyle(color: isInfluencer ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildScrollingNotice() {
    const noticeText =
        "  Notice: Chat is for campaign communication only. Abusive, spam, or "
        "off-topic messages are strictly prohibited. Sharing personal information "
        "is discouraged. Violating these rules may result in account suspension.  ";

    return ClipRect(
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 32,
            color: Colors.deepPurple.shade50,
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              animation: _marqueeController,
              builder: (context, child) {
                final dx = 1.0 - (_marqueeController.value * 5.0);
                return FractionalTranslation(translation: Offset(dx, 0), child: child);
              },
              child: SizedBox(

                child: Text(
                  noticeText,
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Nunito',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _marqueeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(radius: 20, backgroundImage: NetworkImage(widget.brandImage)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.brandName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Nunito',
                  ),
                ),
                const Text(
                  "Official brand chat",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Scrolling notice (marquee)
            _buildScrollingNotice(),
            const SizedBox(height: 3),
            // 🔹 Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
              ),
            ),

            // 🔹 Input box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
