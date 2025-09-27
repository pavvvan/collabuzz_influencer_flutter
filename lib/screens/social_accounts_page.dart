import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/dart/Social_media_service.dart';
import '../services/dart/auth_services.dart';


class SocialAccountsPage extends StatefulWidget {
  const SocialAccountsPage({super.key});

  @override
  State<SocialAccountsPage> createState() => _SocialAccountsPageState();
}

class _SocialAccountsPageState extends State<SocialAccountsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isInstagramConnected = false;
  bool isYouTubeConnected = false;
  Map<String, dynamic>? instagramData;
  Map<String, dynamic>? youtubeData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final data = await AuthServices().getProfile();
    if (data != null) {
      final socials = List<Map<String, dynamic>>.from(data['profileData']['socials'] ?? []);
      setState(() {
        instagramData = socials.firstWhere(
              (s) => s['platform'] == 'instagram',
          orElse: () => {},
        );
        youtubeData = socials.firstWhere(
              (s) => s['platform'] == 'youtube',
          orElse: () => {},
        );
        isInstagramConnected = instagramData != null && instagramData!.isNotEmpty;
        isYouTubeConnected = youtubeData != null && youtubeData!.isNotEmpty;
      });
    }
  }

  Future<void> _showSocialForm(String platform, {Map<String, dynamic>? existingData}) async {
    final contentTypes = platform == "Instagram"
        ? [
      "Festive Celebrations and Traditions",
      "Fashion and Style Posts",
      "Food Photography and Recipes",
      "Travel Diaries and Experiences",
      "Candid Moments and Lifestyle",
      "Short Reels (Dance, Comedy, Lip Sync)",
      "Behind-the-Scenes from Events",
      "Influencer Collaborations",
      "Memes Relevant to Indian Culture",
      "Polls about Current Affairs",
      "Sustainable Living Tips",
      "Health and Wellness Tips",
      "Cultural Heritage Posts",
      "Art and Craft Showcases",
      "Family and Parenting Tips",
      "Motivational Quotes in Local Languages",
      "Sports Highlights and Analysis",
      "Local Business Promotions",
      "DIY Home Decor Ideas",
      "Environmental Awareness Campaigns",
      "Moto Vlog Highlights",
      "UGC",
      "Beauty"
    ]
        : [
      "Vlogs",
      "Cooking Shows",
      "Bollywood News and Reviews",
      "Comedy Sketches",
      "Educational Tutorials",
      "Tech Reviews",
      "Travel Vlogs",
      "Cultural Documentaries",
      "Fitness and Health Tips",
      "Fashion and Beauty Tutorials",
      "Music Covers and Originals",
      "Motivational Talks",
      "Religious and Spiritual Content",
      "Dance Tutorials and Performances",
      "Regional Language Content",
      "Gaming Streams",
      "Social Issues Discussions",
      "Product Reviews",
      "Unboxing Videos",
      "Kids' Content and Cartoons",
      "Pet Care and Training",
      "DIY and Crafting",
      "Art and Painting Tutorials",
      "Book Reviews",
      "Interviews with Influencers and Celebrities",
      "Moto Vlogging",
      "Adventure and Extreme Sports Content",
      "UGC",
      "Beauty"
    ];

    String? selectedContentType = existingData?['contentType'];

    final TextEditingController idController = TextEditingController(text: existingData?['handle'] ?? '');
    final TextEditingController urlController = TextEditingController(text: existingData?['url'] ?? '');
    final TextEditingController followersController = TextEditingController(text: existingData?['followers']?.toString() ?? '');
    final TextEditingController engagementController = TextEditingController(text: existingData?['engagementRate']?.toString() ?? '');
    final TextEditingController likesController = TextEditingController(text: existingData?['avgLikes']?.toString() ?? '');
    final TextEditingController viewsController = TextEditingController(text: existingData?['avgViews']?.toString() ?? '');
    final TextEditingController priceController = TextEditingController(text: existingData?['pricePerPost']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Connect $platform Account",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(controller: idController, label: '$platform ID / Channel Name'),
                  _buildFormField(controller: urlController, label: 'Profile URL'),
                  _buildFormField(controller: followersController, label: 'Followers / Subscribers', isNumber: true),
                  _buildFormField(controller: engagementController, label: 'Engagement Rate (%)', isNumber: true),
                  _buildFormField(controller: likesController, label: 'Avg Likes', isNumber: true),
                  _buildFormField(controller: viewsController, label: 'Avg Views', isNumber: true),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    value: selectedContentType,
                    onChanged: (val) {
                      selectedContentType = val;
                      _formKey.currentState?.validate();
                    },
                    validator: (value) => value == null || value.isEmpty ? 'Please select content type' : null,
                    decoration: InputDecoration(
                      labelText: "Content Type",
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: contentTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type, overflow: TextOverflow.ellipsis)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(controller: priceController, label: 'Price Per Post', isNumber: true),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );

                          final success = await SocialMediaService().updateSocialProfile(
                            platform: platform.toLowerCase(),
                            handle: idController.text.trim(),
                            url: urlController.text.trim(),
                            followers: int.tryParse(followersController.text.trim()),
                            engagementRate: double.tryParse(engagementController.text.trim()),
                            avgLikes: int.tryParse(likesController.text.trim()),
                            avgViews: int.tryParse(viewsController.text.trim()),
                            contentType: selectedContentType,
                            pricePerPost: int.tryParse(priceController.text.trim()),
                          );

                          Navigator.of(context).pop();

                          if (success) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Saved successfully.")),
                            );
                            _fetchProfile();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to save profile.")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF671DD1),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text("Save", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (_) => _formKey.currentState?.validate(),
        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter $label' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String icon,
    Map<String, dynamic>? data,
    required VoidCallback onConnectOrEdit,
  }) {
    bool isConnected = data != null && data.isNotEmpty;
    String handle = isConnected ? (data['handle'] ?? 'No handle') : '';
    bool verified = isConnected ? (data['isVerified'] ?? false) : false;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Image.asset(icon, height: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isConnected
            ? Text('$handle • ${verified ? "Verified ✅" : "Not Verified ❌"}')
            : const Text("No account connected"),
        trailing: ElevatedButton(
          onPressed: onConnectOrEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: isConnected ? Colors.orange : const Color(0xFF671DD1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(isConnected ? 'Edit' : 'Add'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              title: "Instagram",
              icon: "assets/instagram.png",
              data: instagramData,
              onConnectOrEdit: () => _showSocialForm("Instagram", existingData: instagramData),
            ),
            _buildCard(
              title: "YouTube",
              icon: "assets/youtube.png",
              data: youtubeData,
              onConnectOrEdit: () => _showSocialForm("YouTube", existingData: youtubeData),
            ),
          ],
        ),
      ),
    );
  }
}
