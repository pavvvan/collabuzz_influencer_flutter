import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../services/dart/auth_services.dart';
import '../services/dart/campaign_service.dart';
import '../widgets/campaign_card.dart';
import 'campaign_view_page.dart';

class SearchFilterPage extends StatefulWidget {
  const SearchFilterPage({super.key});

  @override
  State<SearchFilterPage> createState() => _SearchFilterPageState();
}

class _SearchFilterPageState extends State<SearchFilterPage> {
  List<String> influencerTypes = [];
  List<String> influencerCategories = [];
  List<String> targetAudiences = [];

  List<String> selectedCampaignTypes = [];
  List<String> selectedPlatforms = [];
  List<String> selectedContentTypes = [];



  String? selectedInfluencerType;
  String? selectedInfluencerCategory;
  String? selectedTargetAudience;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> campaigns = [];
  String? resultMessage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();

    _searchController.addListener(_onSearchChanged);
    // 🔥 Trigger initial search with empty query to fetch all campaigns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onSearchChanged(); // searchController.text is initially ""
    });
  }

  Future<void> _loadMetadata() async {
    final metadata = await AuthServices().getMetadata();
    if (metadata != null) {
      setState(() {
        influencerTypes = List<String>.from((metadata['InfluencerType'] ?? []).map((e) => e['influencerTypeName']));
        influencerCategories = List<String>.from((metadata['InfluencerCategory'] ?? []).map((e) => e['influencerCategoryName']));
        targetAudiences = List<String>.from((metadata['TargentAudience'] ?? []).map((e) => e['targetAudienceName']));
      });
    }
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.length >= 4 || query.isEmpty) {
      setState(() => isLoading = true);
      final result = await CampaignService().searchCampaigns(query);
      setState(() {
        campaigns = result;
        resultMessage = "Total ${result.length} results found!";
        isLoading = false;
      });
    }
  }

  void _applyFilters() async {
    setState(() => isLoading = true);
    final response = await CampaignService().filterCampaigns(
      influencerCategory: selectedInfluencerCategory?.isNotEmpty == true ? selectedInfluencerCategory : null,
      influencerType: selectedInfluencerType?.isNotEmpty == true ? selectedInfluencerType : null,
      campaignType: selectedCampaignTypes.isNotEmpty ? selectedCampaignTypes.first : null,
      platform: selectedPlatforms.isNotEmpty ? selectedPlatforms.first : null,
      contentType: selectedContentTypes.isNotEmpty ? selectedContentTypes.first : null,
      targetAudience: selectedTargetAudience?.isNotEmpty == true ? selectedTargetAudience : null,
    );
    setState(() {
      campaigns = response;
      resultMessage = "Total ${response.length} results found!";
      isLoading = false;
    });
  }

  void _clearFilters() {
    setState(() {
      selectedCampaignTypes.clear();
      selectedPlatforms.clear();
      selectedContentTypes.clear();
      selectedInfluencerType = null;
      selectedInfluencerCategory = null;
      selectedTargetAudience = null;
      campaigns.clear();
      resultMessage = null;
    });
  }

  void _removeFilterChip(String label) {
    setState(() {
      selectedCampaignTypes.remove(label);
      selectedPlatforms.remove(label);
      selectedContentTypes.remove(label);
      if (selectedInfluencerType == label) selectedInfluencerType = null;
      if (selectedInfluencerCategory == label) selectedInfluencerCategory = null;
      if (selectedTargetAudience == label) selectedTargetAudience = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> filterChips = [
      ...selectedCampaignTypes.map((e) => Chip(label: Text(e), onDeleted: () => _removeFilterChip(e))),
      ...selectedPlatforms.map((e) => Chip(label: Text(e), onDeleted: () => _removeFilterChip(e))),
      ...selectedContentTypes.map((e) => Chip(label: Text(e), onDeleted: () => _removeFilterChip(e))),
      if (selectedInfluencerType != null)
        Chip(label: Text(selectedInfluencerType!), onDeleted: () => _removeFilterChip(selectedInfluencerType!)),
      if (selectedInfluencerCategory != null)
        Chip(label: Text(selectedInfluencerCategory!), onDeleted: () => _removeFilterChip(selectedInfluencerCategory!)),
      if (selectedTargetAudience != null)
        Chip(label: Text(selectedTargetAudience!), onDeleted: () => _removeFilterChip(selectedTargetAudience!)),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search campaigns...",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _showFilterBottomSheet(context),
              icon: const Icon(Icons.tune, color: Colors.black),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (filterChips.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ...filterChips,
                  ActionChip(
                    label: const Text("Clear Filters"),
                    avatar: const Icon(Icons.clear, size: 18),
                    onPressed: _clearFilters,
                  )
                ],
              ),
            if (resultMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  resultMessage!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            Expanded(
              child: isLoading
                  ? ListView.builder(
                itemCount: 6,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              )
                  : campaigns.isEmpty
                  ? const Center(child: Text("No campaigns found."))
                  : ListView.builder(
                itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = campaigns[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CampaignViewPage(campaignId: campaign['_id']),
                          ),
                        );
                      },
                      child: CampaignCard(campaign: campaign),
                    );
                  }

              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (_) {
        return FilterBottomSheet(
          selectedCampaignTypes: selectedCampaignTypes,
          selectedPlatforms: selectedPlatforms,
          selectedContentTypes: selectedContentTypes,
          influencerTypes: influencerTypes,
          influencerCategories: influencerCategories,
          targetAudiences: targetAudiences,
          selectedInfluencerType: selectedInfluencerType,
          selectedInfluencerCategory: selectedInfluencerCategory,
          selectedTargetAudience: selectedTargetAudience,
          onApply: (
              types,
              platforms,
              contentTypes,
              type,
              category,
              audience,
              ) {
            setState(() {
              selectedCampaignTypes = types;
              selectedPlatforms = platforms;
              selectedContentTypes = contentTypes;
              selectedInfluencerType = type;
              selectedInfluencerCategory = category;
              selectedTargetAudience = audience;
            });
            Navigator.pop(context);
            _applyFilters();
          },
        );
      },
    );
  }
}




class FilterBottomSheet extends StatefulWidget {
  final List<String> selectedCampaignTypes;
  final List<String> selectedPlatforms;
  final List<String> selectedContentTypes;
  final List<String> influencerTypes;
  final List<String> influencerCategories;
  final List<String> targetAudiences;
  final String? selectedInfluencerType;
  final String? selectedInfluencerCategory;
  final String? selectedTargetAudience;
  final Function(
      List<String>,
      List<String>,
      List<String>,
      String?,
      String?,
      String?
      ) onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedCampaignTypes,
    required this.selectedPlatforms,
    required this.selectedContentTypes,
    required this.influencerTypes,
    required this.influencerCategories,
    required this.targetAudiences,
    required this.selectedInfluencerType,
    required this.selectedInfluencerCategory,
    required this.selectedTargetAudience,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<String> campaignTypes;
  late List<String> platforms;
  late List<String> contentTypes;
  String? influencerType;
  String? influencerCategory;
  String? targetAudience;

  // ✅ State variables
  String? selectedCampaignType;
  String? selectedPlatform;
  String? selectedContentType;

  @override
  void initState() {
    super.initState();
    campaignTypes = [...widget.selectedCampaignTypes];
    platforms = [...widget.selectedPlatforms];
    contentTypes = [...widget.selectedContentTypes];
    influencerType = widget.selectedInfluencerType;
    influencerCategory = widget.selectedInfluencerCategory;
    targetAudience = widget.selectedTargetAudience;

  }

  void _toggle(List<String> list, String value) {
    setState(() {
      list.contains(value) ? list.remove(value) : list.add(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Campaign Type", style: TextStyle(fontWeight: FontWeight.w600)),




// ✅ Campaign Type (Single Selection)
        Wrap(
        spacing: 8,
        children: ['cash', 'barter'].map((type) {
          return FilterChip(
            label: Text(type),
            selected: selectedCampaignType == type,
            onSelected: (isSelected) {
              setState(() {
                selectedCampaignType = isSelected ? type : null;
              });
            },
          );
        }).toList(),
      ),
      const SizedBox(height: 16),

// ✅ Platform (Single Selection)
      const Text("Platform", style: TextStyle(fontWeight: FontWeight.w600)),
      Wrap(
        spacing: 8,
        children: ['instagram', 'youtube'].map((platform) {
          return FilterChip(
            label: Text(platform),
            selected: selectedPlatform == platform,
            onSelected: (isSelected) {
              setState(() {
                selectedPlatform = isSelected ? platform : null;
              });
            },
          );
        }).toList(),
      ),
      const SizedBox(height: 16),

// ✅ Content Type (Single Selection)
      const Text("Content Type", style: TextStyle(fontWeight: FontWeight.w600)),
      Wrap(
        spacing: 8,
        children: ['Reels', 'Story', 'Post', 'Video', 'Video Ad'].map((type) {
          return FilterChip(
            label: Text(type),
            selected: selectedContentType == type,
            onSelected: (isSelected) {
              setState(() {
                selectedContentType = isSelected ? type : null;
              });
            },
          );
        }).toList(),
      ),

      const SizedBox(height: 16),
            const Text("Influencer Type", style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Select Influencer Type"),
              value: influencerType,
              items: widget.influencerTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => influencerType = val),
            ),
            const SizedBox(height: 16),
            const Text("Influencer Category", style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Select Influencer Category"),
              value: influencerCategory,
              items: widget.influencerCategories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => influencerCategory = val),
            ),
            const SizedBox(height: 16),
            const Text("Target Audience", style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Select Target Audience"),
              value: targetAudience,
              items: widget.targetAudiences
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => targetAudience = val),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(
                    selectedCampaignType != null ? [selectedCampaignType!] : [],
                    selectedPlatform != null ? [selectedPlatform!] : [],
                    selectedContentType != null ? [selectedContentType!] : [],
                    influencerType,
                    influencerCategory,
                    targetAudience,
                  );


                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF671DD1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Apply Filters"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
