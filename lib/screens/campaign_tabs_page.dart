import 'package:flutter/material.dart';
import 'ongoing_campaigns_page.dart';
import 'requested_campaigns_page.dart';
import 'completed_campaigns_page.dart';

class CampaignTabTogglePage extends StatefulWidget {
  const CampaignTabTogglePage({super.key});

  @override
  State<CampaignTabTogglePage> createState() => _CampaignTabTogglePageState();
}

class _CampaignTabTogglePageState extends State<CampaignTabTogglePage> {
  final List<String> tabs = ["Ongoing", "Requested", "Completed"];
  int selectedIndex = 0;
  final PageController _pageController = PageController();

  void onTabSelected(int index) {
    setState(() => selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 🔘 Toggle pill tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected = selectedIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTabSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              tabs[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔄 Page View for tabs
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => selectedIndex = index);
                },
                children: const [
                  OnGoingCampaignPage(),
                  RequestedCampaignPage(),
                  CompletedCampaignPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
