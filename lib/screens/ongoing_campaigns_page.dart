import 'package:flutter/material.dart';
import '../../widgets/campaign_card.dart';
import '../../widgets/empty_campaign_placeholder.dart';
import '../services/dart/campaign_service.dart';

import 'campaign_view_page.dart'; // ✅ import your detail screen

class OnGoingCampaignPage extends StatefulWidget {
  const OnGoingCampaignPage({super.key});

  @override
  State<OnGoingCampaignPage> createState() => _OnGoingCampaignPageState();
}

class _OnGoingCampaignPageState extends State<OnGoingCampaignPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> campaigns = [];

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  Future<void> _fetchCampaigns() async {
    final service = CampaignService();
    final result = await service.getInfluencerCampaigns("ongoing");
    setState(() {
      campaigns = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchCampaigns,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : campaigns.isEmpty
            ? const EmptyCampaignPlaceholder(
          icon: Icons.campaign_outlined,
          title: "Ongoing Campaigns",
          subtitle: "All your live campaigns appear here.",
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final campaign = campaigns[index];
            return CampaignCard(
              campaign: campaign,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CampaignViewPage(
                      campaignId: campaign['_id'],
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
}
