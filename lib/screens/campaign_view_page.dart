import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dart/auth_services.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';


import '../services/dart/campaign_service.dart';
import 'campaign_work_Flow.dart';
import 'chat/influencer_chat_dialog.dart';

class CampaignViewPage extends StatefulWidget {
  final String campaignId;

  const CampaignViewPage({super.key, required this.campaignId});

  @override
  State<CampaignViewPage> createState() => _CampaignViewPageState();
}

class _CampaignViewPageState extends State<CampaignViewPage> {
  Map<String, dynamic>? campaign;
  bool loading = true;

  String? _influencerId;
  bool showChatButton = false;
  bool showRequestButton = false;


  @override
  void initState() {
    super.initState();
    _loadCampaign();
  }

  Future<void> _loadCampaign() async {
    try {
      final result = await CampaignService().getCampaignsByIds([widget.campaignId]);
      final profileResponse = await AuthServices().getProfile();

      _influencerId = profileResponse?['profileData']?['_id'];

      final campaignData = result.isNotEmpty ? result.first : null;

      bool chat = false;
      bool request = false;

      if (campaignData != null && _influencerId != null) {
        final requests = List<Map<String, dynamic>>.from(campaignData['requests'] ?? []);

        // Default: allow request button if influencer never requested
        request = true;

        for (var req in requests) {
          if (req['influencer'] == _influencerId) {
            final status = (req['influencerStatus'] ?? '').toLowerCase();

            if (status == 'shortlisted' || status == 'awarded') {
              chat = true;
              request = false;
              break;
            } else if (status == 'rejected') {
              chat = false;
              request = true; // can re-request
            } else {
              // requested or pending
              chat = false;
              request = false; // hide buttons while pending
            }
          }
        }
      }

      setState(() {
        campaign = campaignData;
        showChatButton = chat;
        showRequestButton = request;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading campaign: $e");
      setState(() => loading = false);
    }
  }


  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(color: Colors.black87)),
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _openImageViewer(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.white,
      builder: (_) => Stack(
        children: [
          Container(
            color: Colors.white,
            child: PhotoView(
              imageProvider: NetworkImage(url),
              backgroundDecoration: const BoxDecoration(color: Colors.white),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.close, size: 24, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichSection(String title, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox();

    final Map<String, String> descriptions = {
      "Description": "Overview of the campaign, including its goal and what the brand is offering.",
      "Brief to Influencer": "Detailed instructions for influencers on how to create and post content for this campaign.",
      "Content Guidance": "Guidelines on style, tone, and visual elements to maintain brand identity.",
      "Deliverables": "The exact number and type of posts, stories, or reels the influencer must provide.",
      "Caption": "The text that the brand wants included in posts to ensure consistent messaging.",
      "Influencer Category": "The niche or segment of influencer this campaign is targeting (e.g., Fashion, Food, Tech).",
      "Influencer Type": "The scale of influencer (Nano, Micro, Macro, Celebrity) suitable for this campaign.",
      "Target Audience": "The demographic the brand wants to reach (age, interests, or market segment).",
      "Hashtags": "The hashtags that must be included to increase reach and engagement.",
      "Sponsored Account": "The brand account that influencers must tag when posting content.",
      "Platform": "The social media platform where the content should be posted (Instagram, YouTube, etc.).",
      "Duration": "The start and end dates for the campaign. Posts must be made during this period.",
    };

    final textSpan = TextSpan(
      text: value,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
    );

    final tp = TextPainter(
      text: textSpan,
      maxLines: 4,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 64);

    final exceedsLimit = tp.didExceedMaxLines;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Heading with inline info icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF671DD1),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  final desc = descriptions[title] ?? "No description available.";
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF671DD1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Got it", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.grey,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ✅ Section Content
          Text(
            value,
            maxLines: exceedsLimit ? 4 : null,
            overflow: exceedsLimit ? TextOverflow.ellipsis : null,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),

          if (exceedsLimit)
            GestureDetector(
              onTap: () => _showFullTextDialog(title, value),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Read more",
                  style: TextStyle(
                    color: const Color(0xFF671DD1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case "instagram":
        return Image.asset('assets/instagram.png', width: 40, height: 40);
      case "youtube":
        return Image.asset('assets/youtube.png', width: 45, height: 30);
      default:
        return const SizedBox();
    }
  }

  // void _showPitchBottomSheet(BuildContext context, String campaignName) {
  //   final TextEditingController _pitchController = TextEditingController();
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.white,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return Padding(
  //         padding: MediaQuery.of(context).viewInsets,
  //         child: Padding(
  //           padding: const EdgeInsets.all(20),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text("Pitch for $campaignName",
  //                   style: const TextStyle(
  //                       fontSize: 20, fontWeight: FontWeight.bold)),
  //               const SizedBox(height: 10),
  //               const Text(
  //                 "Tell the brand why you're a great fit for this campaign.",
  //                 style: TextStyle(fontSize: 14, color: Colors.black54),
  //               ),
  //               const SizedBox(height: 20),
  //               TextField(
  //                 controller: _pitchController,
  //                 maxLines: 5,
  //                 decoration: InputDecoration(
  //                   hintText: "Type your pitch here...",
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   filled: true,
  //                   fillColor: Colors.grey.shade100,
  //                 ),
  //               ),
  //               const SizedBox(height: 20),
  //               SizedBox(
  //                 width: double.infinity,
  //                 child: ElevatedButton(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: const Color(0xFF671DD1),
  //                     padding: const EdgeInsets.symmetric(vertical: 14),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(30),
  //                     ),
  //                   ),
  //                   onPressed: () async {
  //                     final pitch = _pitchController.text.trim();
  //
  //                     if (pitch.isEmpty) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(content: Text("Please enter your pitch")),
  //                       );
  //                       return;
  //                     }
  //
  //                     try {
  //                       final profileResponse = await AuthServices().getProfile();
  //
  //                       final influencer = profileResponse?['profileData'];
  //
  //                       final influencerId = influencer['_id'];
  //                       final influencerName = influencer['influencerName'];
  //                       final campaignImage = influencer['profileImage'];
  //
  //
  //
  //                       final campaignUrl = campaign!['appWebLink'] ?? '';
  //
  //                       final campaignRequest = {
  //                         "influencer": influencerId,
  //                         "influencerName": influencerName,
  //                         "influencerPitch": pitch,
  //                         "influencerStatus": "requested",
  //                         "campaignImage": campaignImage,
  //                         "campaignURL": campaignUrl
  //
  //                       };
  //
  //                       print("\u{1F3AF} Final Campaign Request:\n${jsonEncode(campaignRequest)}");
  //
  //                       Navigator.pop(context);
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(content: Text("Request ready! See console.")),
  //                       );
  //                     } catch (e) {
  //                       debugPrint("\u{274C} Error preparing request: $e");
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(content: Text("Something went wrong.")),
  //                       );
  //                     }
  //                   },
  //                   child: const Text("Send Request to Participate",
  //                       style: TextStyle(color: Colors.white)),
  //                 ),
  //               )
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void _showPitchBottomSheet(BuildContext context, String campaignName) {
    final TextEditingController _pitchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isLoading = false; // 👈 Local loading state

            _pitchController.addListener(() {
              setModalState(() {}); // Rebuild to enable/disable button
            });

            Future<void> _sendRequest() async {
              final pitch = _pitchController.text.trim();
              if (pitch.length < 20) return;

              setModalState(() => isLoading = true);

              try {
                final profileResponse = await AuthServices().getProfile();
                final influencer = profileResponse?['profileData'];

                final influencerId = influencer['_id'];
                final influencerName = influencer['influencerName'];
                final influencerPhoto = influencer['profileImage'];
                final campaignImage = campaign!['CampaignPhoto'];
                final influencerEmail = influencer['email'];

                final prefs = await SharedPreferences.getInstance();
                final userDataString = prefs.getString("userData");
                Map<String, dynamic> userData = {};
                if (userDataString != null) {
                  try {
                    userData = json.decode(userDataString);
                  } catch (e) {
                    debugPrint("Error parsing userData: $e");
                  }
                }

                final brandEmail = userData['email'] ?? '';
                final brandName = userData['name'] ?? '';

                final campaignRequest = {
                  "influencerName": influencerName,
                  "influencerPitch": pitch,
                  "campaignName": campaign!['campaignName'],
                  "campaignImage": influencerPhoto,
                  "influencerEmail": influencerEmail,
                  "brandEmail": brandEmail,
                  "brandName": brandName,
                  "influencerId": influencerId,
                  "campaignId": campaign!['campaignId'],
                };

                debugPrint(campaignRequest.toString());

                final response =
                await CampaignService().sendCampaignRequest(campaignRequest);

                if (context.mounted) {
                  Navigator.pop(context); // close bottom sheet
                  _showResponseDialog(
                    title: response['status'] == true
                        ? "Campaign Request Sent!"
                        : "Request Failed",
                    description: response['message'] ??
                        "Something went wrong. Please try again.",
                    isSuccess: response['status'] == true,
                  );
                }
              } on DioException catch (dioError) {
                Navigator.pop(context);
                final message = dioError.response?.data?['message'] ??
                    "Something went wrong.";
                _showResponseDialog(
                  title: "Request Failed",
                  description: message,
                  isSuccess: false,
                );
              } catch (e) {
                Navigator.pop(context);
                debugPrint("❌ Error preparing request: $e");
                _showResponseDialog(
                  title: "Something went wrong",
                  description: "Please try again later.",
                  isSuccess: false,
                );
              } finally {
                setModalState(() => isLoading = false);
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pitch for $campaignName",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text(
                      "Tell the brand why you're a great fit for this campaign.",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _pitchController,
                      maxLines: 5,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: "Type your pitch here...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        counterText: "",
                      ),
                    ),
                    Text(
                      "Min 20 chars : ${_pitchController.text.length} / 200 characters",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF671DD1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _pitchController.text.trim().length < 20 || isLoading
                            ? null
                            : _sendRequest,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoading) ...[
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            const Text(
                              "Send Request to Participate",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _showResponseDialog({
    required String title,
    required String description,
    bool isSuccess = true,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 48,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black)),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF671DD1))),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // compute awardedToMe: true when any awardedInfluencers entry has this influencer id
    final bool awardedToMe = (() {
      if (campaign == null || _influencerId == null) return false;
      final List<dynamic> awarded = (campaign!['awardedInfluencers'] as List<dynamic>?) ?? [];
      for (final a in awarded) {
        try {
          final String influencerId = a['influencer']?.toString() ?? '';
          final String status = (a['status']?.toString() ?? '').toLowerCase();
          if (influencerId.isNotEmpty && influencerId == _influencerId) {
            // consider it awarded if status == 'awarded' OR if it exists (defensive)
            if (status == 'awarded' || status == 'awarded_by_brand' || status == '') {
              return true;
            }
            if (status == 'awarded') return true;
          }
        } catch (_) {
          // ignore malformed entry and continue
        }
      }
      return false;
    })();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, // White background
        elevation: 0.5, // subtle shadow
        iconTheme: const IconThemeData(color: Colors.black), // back icon color
        title: const Text(
          "Campaign Details",
          style: TextStyle(
            fontFamily: 'Nunito', // 🔹 Your custom font
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true, // optional, for centered title
      ),

      // If awardedToMe is true show a bottom nav bar; otherwise null
      bottomNavigationBar: awardedToMe
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2)),
              ],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "This campaign is awarded to you",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Start the workflow to submit drafts & proofs.",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (campaign != null && _influencerId != null)
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CampaignWorkflowPage(
                            campaignId: campaign?['_id'],
                            influencerId: _influencerId!,
                          ),
                        ),
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF671DD1),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Go to Workflow", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          : null,

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : campaign == null
          ? const Center(child: Text("Campaign not found."))
          : SafeArea(
        child: ListView(
          // keep your existing children intact; add bottom padding so content isn't covered
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => _openImageViewer(campaign!['CampaignCoverPhoto']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      campaign!['CampaignCoverPhoto'] ?? '',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (campaign!['CampaignPhoto'] != null)
                  Positioned(
                    bottom: -40,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => _openImageViewer(campaign!['CampaignPhoto']),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            campaign!['CampaignPhoto'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 60),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ First Row: 90% Campaign Name + 10% Platform Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campaign name (90%)
                    Expanded(
                      flex: 9,
                      child: Text(
                        campaign!['campaignName'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Platform Icon (10%)
                    Expanded(
                      flex: 1,
                      child: _getPlatformIcon(campaign!['platform'] ?? ''),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ✅ New: Created by Brand Name
                Row(
                  children: [
                    Text(
                      'Created by ',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      campaign!['brandName'] ?? '',
                      style: TextStyle(
                        color: const Color(0xFF671DD1),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ✅ Second Row: Chips (Campaign Status, Content Type, Campaign Type)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    // Campaign Status Chip with dynamic color
                    Chip(
                      label: Text(
                        capitalizeFirst(campaign!['campaignStatus'] ?? 'Unknown'),
                        style: TextStyle(
                          color: _getStatusTextColor(campaign!['campaignStatus']),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: _getStatusColor(campaign!['campaignStatus']),
                    ),

                    if (campaign!['contentType'] != null)
                      Chip(
                        label: Text(
                          capitalizeFirst(campaign!['contentType']),
                          style: const TextStyle(color: Colors.deepPurple),
                        ),
                        backgroundColor: Colors.deepPurple[50],
                      ),

                    if (campaign!['campaignType'] != null)
                      Chip(
                        label: Text(
                          capitalizeFirst(campaign!['campaignType']),
                          style: const TextStyle(color: Colors.green),
                        ),
                        backgroundColor: Colors.green[50],
                      ),

                    if (campaign!['platform'] != null)
                      Chip(
                        label: Text(
                          capitalizeFirst(campaign!['platform']),
                          style: const TextStyle(color: Colors.red),
                        ),
                        backgroundColor: Colors.red[50],
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildRichSection("Description", campaign!['CampaignDescription']),

            _buildRichSection("Brief to Influencer", campaign!['BriefToInfluencer']),
            _buildRichSection("Content Guidance", campaign!['contentGuidance']),
            // _buildRichSection("Content Type", campaign!['campaignType']),
            _buildRichSection("Deliverables", campaign!['CampaignDeliverables']),
            _buildRichSection("Caption", campaign!['caption']),
            _buildRichSection("Influencer Category", campaign!['influencerCategory']),
            _buildRichSection("Influencer Type", campaign!['influencerType']),
            _buildRichSection("Target Audience", campaign!['targetAudience']),
            _buildRichSection("Hashtags", (campaign!['hashTags'] ?? []).join(', ')),
            _buildRichSection("Sponsored Account", (campaign!['sponsoredAccount'] ?? [])),
            _buildRichSection("Platform", campaign!['platform']),
            _buildRichSection("Duration", campaign!['campaignDurationFrom'] + " - " + campaign!['campaignDurationTo']),

            const Divider(height: 32),
            const Text("Asset References", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            if ((campaign!['assets'] ?? []).isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: campaign!['assets'].length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        campaign!['assets'][index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text("Product", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            if (campaign!['product'] != null) ...[
              ...(() {
                final products = campaign!['product'];
                final productList = products is List ? products : [products];

                return productList.map<Widget>((product) {
                  return Card(
                    color: Colors.white, // White card
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Bigger Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: product['image'] != null && product['image'].toString().isNotEmpty
                                ? Image.network(
                              product['image'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.shopping_bag, color: Colors.grey, size: 32),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ✅ Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['productName'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product['productCategory'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // ✅ Price Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    product['productPrice'] != null ? '₹${product['productPrice']}' : 'Free',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList();
              })(),
            ],

            const SizedBox(height: 32),
            if (showChatButton) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InfluencerChatDialog(
                        brandName: campaign!['brandName'] ?? '',
                        brandImage: campaign!['CampaignPhoto'] ?? '',
                        brandBio: 'Official brand chat',
                        campaignId: campaign!['_id'],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Open Chat", style: TextStyle(color: Colors.white)),
              ),
            ] else if (showRequestButton) ...[
              ElevatedButton(
                onPressed: () async {
                  try {
                    final response = await AuthServices().getProfile();
                    final completion = response?['profileCompletionPercentage'];
                    if (completion == 100) {
                      _showPitchBottomSheet(context, campaign!['campaignName']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please complete your profile before requesting")),
                      );
                    }
                  } catch (e) {
                    debugPrint("Error fetching profile: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Something went wrong. Please try again.")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF671DD1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Request Campaign", style: TextStyle(color: Colors.white)),
              ),
            ]
          ],
        ),
      ),
    );
  }


  Future<void> _launchProductLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

// Base status color (for text)
  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'created':
        return Colors.black;
      case 'live':
        return Colors.purple;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'paused':
        return Colors.amber[800]!; // darker amber for visibility
      default:
        return Colors.black54;
    }
  }

// Lighter background for chip
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'created':
        return Colors.grey[100]!;
      case 'live':
        return Colors.purple[50]!;
      case 'ongoing':
        return Colors.orange[50]!;
      case 'completed':
        return Colors.green[50]!;
      case 'rejected':
        return Colors.red[50]!;
      case 'paused':
        return Colors.amber[50]!;
      default:
        return Colors.grey[100]!;
    }
  }



  String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }



}
