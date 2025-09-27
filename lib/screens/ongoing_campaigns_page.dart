import 'package:flutter/material.dart';
import '../services/dart/campaign_service.dart';
import '../widgets/campaign_card.dart';
import 'campaign_view_page.dart';


class OnGoingCampaignPage extends StatefulWidget {
  const OnGoingCampaignPage({super.key});

  @override
  State<OnGoingCampaignPage> createState() => _OnGoingCampaignPageState();
}

class _OnGoingCampaignPageState extends State<OnGoingCampaignPage> {
  final CampaignService _campaignService = CampaignService();
  List<dynamic> _campaigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAwardedCampaigns();
  }

  Future<void> _fetchAwardedCampaigns() async {
    final campaigns = await _campaignService.getAwardedCampaigns();
    setState(() {
      _campaigns = campaigns;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _campaigns.isEmpty
          ? const Center(child: Text("No awarded campaigns found"))
          : ListView.builder(
        itemCount: _campaigns.length,
        itemBuilder: (context, index) {
          final campaign = _campaigns[index];
          return CampaignCard(
            campaign: campaign,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CampaignViewPage(campaignId: campaign['_id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

