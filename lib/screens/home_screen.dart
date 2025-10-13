import 'dart:async';
import 'package:flutter/material.dart';
import 'package:influencer_dashboard/screens/search_filter_page.dart';
import 'package:shimmer/shimmer.dart';
import '../services/dart/campaign_service.dart';
import '../widgets/campaign_card.dart';
import 'campaign_view_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> campaigns = [];
  bool loading = true;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  final List<String> banners = [
    //'assets/home_card_1.png',
    'assets/banner2.png',
    'assets/banner4.png',
    'assets/banner2.png',
    'assets/banner4.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = nextPage);
      }
    });
  }

  Future<void> _loadCampaigns() async {
    try {
      final result = await CampaignService().getCampaigns();
      setState(() {
        campaigns = result;
        loading = false;
      });
    } catch (e) {
      debugPrint('Load error: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Banner Section ──
              SizedBox(
                height: 250,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemCount: banners.length,
                        itemBuilder: (context, index) {
                          return _topBannerCard(banners[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        banners.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 10 : 6,
                          height: _currentPage == index ? 10 : 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index ? Color(0xFF671DD1) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // ── Section Header ──
               Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Recent Campaigns", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SearchFilterPage()),
                        );
                      },
                      child: Text(
                        "View All",
                        style: TextStyle(
                          color: Colors.grey,


                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 12),

              // ── Campaign Cards or Shimmer ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: loading
                    ? _shimmerList()
                    : Column(
                  children: campaigns.map((campaign) {
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
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

    );
  }

  Widget _topBannerCard(String asset) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: DecorationImage(
            image: AssetImage(asset),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _shimmerList() {
    return Column(
      children: List.generate(
        6,
            (index) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 90,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
