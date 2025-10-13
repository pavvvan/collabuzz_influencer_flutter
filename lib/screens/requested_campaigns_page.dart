import 'package:flutter/material.dart';
import '../../widgets/campaign_card.dart';
import '../../widgets/empty_campaign_placeholder.dart';
import '../services/dart/campaign_service.dart';

import 'campaign_view_page.dart'; // ✅ import your detail page

class RequestedCampaignPage extends StatefulWidget {
  const RequestedCampaignPage({super.key});

  @override
  State<RequestedCampaignPage> createState() => _RequestedCampaignPageState();
}

class _RequestedCampaignPageState extends State<RequestedCampaignPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> campaigns = [];

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  Future<void> _fetchCampaigns() async {
    final service = CampaignService();
    final result = await service.getInfluencerCampaigns("requested");
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
          icon: Icons.hourglass_empty_rounded,
          title: "Requested Campaigns",
          subtitle: "Campaigns you have requested appear here.",
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
