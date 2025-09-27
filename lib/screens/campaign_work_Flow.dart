// campaign_workflow_page_live.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:influencer_dashboard/screens/post_live_dialog.dart';
import 'package:influencer_dashboard/screens/submit_analytics_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/dart/campaign_service.dart';
import 'campaign_contract_dialog.dart';
import 'chat/influencer_chat_dialog.dart';
import 'content_draft_dialog.dart';

/// Simple data model for a milestone item
class MilestoneItem {
  final String key; // Identifier/key for the milestone
  final String title;
  final String status; // e.g., pending, submitted, completed, acknowledged
  final Map<String, dynamic> dueAt; // { draftDueAt, goLiveDueAt, analyticsDueAt }

  MilestoneItem({
    required this.key,
    required this.title,
    required this.status,
    required this.dueAt,
  });
}

class CampaignWorkflowPage extends StatefulWidget {
  final String campaignId;
  final String influencerId;

  const CampaignWorkflowPage({
    Key? key,
    required this.campaignId,
    required this.influencerId,
  }) : super(key: key);

  @override
  State<CampaignWorkflowPage> createState() => _CampaignWorkflowPageState();
}

class _CampaignWorkflowPageState extends State<CampaignWorkflowPage> {
  Map<String, dynamic>? _campaign;
  List<MilestoneItem> _milestones = [];
  double _progress = 0.0;
  bool _loading = true;
  bool _actionLoading = false;

  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _fetchCampaign();
    _poller = Timer.periodic(const Duration(seconds: 8), (_) => _fetchCampaign());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _fetchCampaign() async {
    try {
      final res = await CampaignService().getCampaignsByIds([widget.campaignId]);
      if (res.isNotEmpty) {
        final campaign = res.first as Map<String, dynamic>;
        _applyCampaignData(campaign);
      } else {
        setState(() {
          _campaign = null;
          _milestones = [];
          _progress = 0.0;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching campaign: $e');
      setState(() => _loading = false);
    }
  }

  void _applyCampaignData(Map<String, dynamic> campaign) {
    Map<String, dynamic>? myAward;
    final awarded = (campaign['awardedInfluencers'] as List<dynamic>?) ?? [];
    for (final a in awarded) {
      try {
        if ((a['influencer']?.toString() ?? '') == widget.influencerId) {
          myAward = Map<String, dynamic>.from(a as Map);
          break;
        }
      } catch (_) {}
    }

    final rawMilestones = (myAward != null && myAward['milestones'] is List)
        ? (myAward['milestones'] as List<dynamic>)
        : ((campaign['milestones'] is List) ? (campaign['milestones'] as List<dynamic>) : []);

    final items = rawMilestones.map<MilestoneItem>((m) {
      final mm = m as Map<String, dynamic>;
      return MilestoneItem(
        key: mm['key']?.toString() ?? mm['title']?.toString() ?? UniqueKey().toString(),
        title: mm['title']?.toString() ?? 'Milestone',
        status: (mm['status']?.toString() ?? 'pending').toLowerCase(),
        dueAt: (mm['deadlines'] is Map) ? Map<String, dynamic>.from(mm['deadlines']) : {},
      );
    }).toList();

    final completedCount = items
        .where((it) => it.status == 'completed' || it.status == 'submitted' || it.status == 'acknowledged')
        .length;
    final prog = items.isEmpty ? 0.0 : (completedCount / items.length);

    setState(() {
      _campaign = campaign;
      _milestones = _withContractAndBrief(items);

      _progress = prog;
      _loading = false;
    });
  }

  List<MilestoneItem> _withContractAndBrief(List<MilestoneItem> items) {
    final contract = _campaign?['awardedInfluencers']?[0]?['contract'] ?? {};
    final isSigned = contract['influencerSignedAt'] != null;

    final contractItem = MilestoneItem(
      key: 'contract',
      title: 'Contract',
      status: isSigned ? 'accepted' : 'pending',
      dueAt: {},
    );

    return [contractItem, ...items];
  }


  // ---------------- Contract Actions ----------------
  Future<void> _acceptContract(Map<String, dynamic> contract) async {
    setState(() => _actionLoading = true);
    try {
      final resp = await CampaignService().contractAction(
        campaignId:  _campaign!['_id'],
        action: "accept",
      );
      if (resp['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract accepted')));
        _fetchCampaign();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? 'Failed')));
      }
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  Future<void> _rejectContract(Map<String, dynamic> contract) async {
    setState(() => _actionLoading = true);
    try {
      final resp = await CampaignService().contractAction(
        campaignId:  _campaign!['_id'],
        action: "reject",
      );
      if (resp['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract rejected')));
        _fetchCampaign();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? 'Failed')));
      }
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  // ---------------- Support & Chat ----------------
  Future<void> _openWhatsAppSupport() async {
    String influencerName = widget.influencerId;
    try {
      final awarded = (_campaign?['awardedInfluencers'] as List<dynamic>?) ?? [];
      for (final a in awarded) {
        if ((a['influencer']?.toString() ?? '') == widget.influencerId) {
          influencerName = a['influencerName']?.toString() ?? influencerName;
          break;
        }
      }
    } catch (_) {}
    final campaignName = _campaign?['campaignName']?.toString() ?? '';
    final text = Uri.encodeComponent('Hi, I am "$influencerName", I need help in campaign "$campaignName"');
    final url = Uri.parse('https://wa.me/919743111825?text=$text');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
    }
  }

  void _chatWithBrand() {
    final brandName = _campaign?['brandName']?.toString() ?? '';
    final brandImage = _campaign?['CampaignPhoto']?.toString() ?? '';
    final campaignId = _campaign?['_id']?.toString() ?? widget.campaignId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InfluencerChatDialog(
          brandName: brandName,
          brandImage: brandImage,
          brandBio: 'Official brand chat',
          campaignId: campaignId,
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Campaign Workflow', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _campaign == null
          ? const Center(child: Text('Campaign not found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Campaign Card
            _buildCampaignHeader(),

            const SizedBox(height: 14),

            // Progress + Support/Chat
            _buildProgressSection(),

            const SizedBox(height: 16),

            // Contract card if not signed
            _buildContractIfNeeded(),

            const SizedBox(height: 18),

            // Milestones
            _buildMilestonesCard(),

            const SizedBox(height: 18),

            // Campaign Details
            _buildCampaignDetailsCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _campaign!['CampaignPhoto'] != null
                    ? Image.network(_campaign!['CampaignPhoto'], fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 40),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_campaign!['campaignName'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(_campaign!['brandName']?.toString() ?? '-',
                      style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      (_campaign!['campaignType'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Campaign Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 12,
            backgroundColor: Colors.white,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('${(_progress * 100).round()}%',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const Spacer(),
            const Text('Completed', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openWhatsAppSupport,
                icon: const Icon(Icons.support_agent, color: Colors.green),
                label: const Text('Support'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _chatWithBrand,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat with Brand'),
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContractIfNeeded() {
    final awarded = (_campaign?['awardedInfluencers'] as List<dynamic>?) ?? [];
    final myAward = awarded.cast<Map<String, dynamic>?>().firstWhere(
          (a) => (a?['influencer']?.toString() ?? '') == widget.influencerId,
      orElse: () => null,
    );

    if (myAward != null && myAward['contract'] != null) {
      final contract = Map<String, dynamic>.from(myAward['contract']);
      if (contract['influencerSignedAt'] == null) {
        return _buildContractCard(myAward);
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildContractCard(Map<String, dynamic> award) {
    final deliverables = Map<String, dynamic>.from(award['deliverables'] ?? {});
    final deadlines = Map<String, dynamic>.from(award['deadlines'] ?? {});
    final agreed = Map<String, dynamic>.from(award['agreed'] ?? {});
    final contract = Map<String, dynamic>.from(award['contract'] ?? {});

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Campaign Contract", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("Deliverables", style: TextStyle(fontWeight: FontWeight.w600)),
          Text("Posts: ${deliverables['postCount'] ?? 0}"),
          Text("Stories: ${deliverables['storyCount'] ?? 0}"),
          Text("Videos: ${deliverables['videoCount'] ?? 0}"),
          Text("Reels: ${deliverables['reelCount'] ?? 0}"),
          const SizedBox(height: 12),
          const Text("Deadlines", style: TextStyle(fontWeight: FontWeight.w600)),
          Text("Draft Due: ${_formatDate(deadlines['draftDueAt'] ?? '')}"),
          Text("Go-Live Due: ${_formatDate(deadlines['goLiveDueAt'] ?? '')}"),
          Text("Analytics Due: ${_formatDate(deadlines['analyticsDueAt'] ?? '')}"),
          const SizedBox(height: 12),
          const Text("Agreed Terms", style: TextStyle(fontWeight: FontWeight.w600)),
          Text("Currency: ${agreed['currency'] ?? '-'}"),
          if ((agreed['barterNotes'] ?? '').toString().isNotEmpty)
            Text("Notes: ${agreed['barterNotes']}"),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _actionLoading ? null : () => _rejectContract(contract),
                  child: const Text("Reject", style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _actionLoading ? null : () => _acceptContract(contract),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF671DD1)),
                  child: const Text("Accept Contract", style: TextStyle(color: Colors.white)), // ✅ white text
                ),
              ),
            ],
          )
        ]),
      ),
    );
  }

  Widget _buildMilestonesCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Milestones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _milestones.length,
              itemBuilder: (_, i) {
                final item = _milestones[i];
                final isLast = i == _milestones.length - 1;
                return _milestoneTimelineTile(item, isLast);
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _milestoneTileReadOnly(MilestoneItem item) {
    final nextPending = _milestones.firstWhere(
          (m) => m.status == 'pending',
      orElse: () => _milestones.last,
    );

    final isCurrent = item.key == nextPending.key;

    return GestureDetector(
      onTap: () {
        if (item.key == 'contract') {
          _showContractDialog(item);
        } else if (item.key == 'brief_ack') {
          _showBriefDialog(item);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrent ? Colors.green : Colors.grey.shade300,
            width: 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(_milestoneSubtitle(item),
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(item.status.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }


  void _showBriefDialog(MilestoneItem milestone) {
    final deliverables =
    Map<String, dynamic>.from(_campaign?['deliverables'] ?? {});

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Campaign Brief",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),

                // Brief text
                Text(
                  _campaign?['BriefToInfluencer'] ?? 'No brief available',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Deliverables section
                if (deliverables.values
                    .any((val) => (val is int && val > 0))) ...[
                  const Text(
                    "Deliverables",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),

                  if ((deliverables['postCount'] ?? 0) > 0)
                    Text("• ${deliverables['postCount']} Post(s)"),

                  if ((deliverables['storyCount'] ?? 0) > 0)
                    Text("• ${deliverables['storyCount']} Story(ies)"),

                  if ((deliverables['videoCount'] ?? 0) > 0)
                    Text("• ${deliverables['videoCount']} Video(s)"),

                  if ((deliverables['reelCount'] ?? 0) > 0)
                    Text("• ${deliverables['reelCount']} Reel(s)"),

                  if ((deliverables['other'] ?? '').toString().isNotEmpty)
                    Text("• ${deliverables['other']}"),
                  const SizedBox(height: 16),
                ],

                // Action buttons (only if milestone pending)
                if (milestone.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await CampaignService().milestoneAction(
                              campaignId: _campaign!['_id'],
                              milestoneKey: milestone.key,
                              action: "reject",
                            );
                            _fetchCampaign();
                          },
                          child: const Text(
                            "Reject",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await CampaignService().milestoneAction(
                              campaignId: _campaign!['_id'],
                              milestoneKey: milestone.key,
                              action: "accept",
                            );
                            _fetchCampaign();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Acknowledge",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }



  String _milestoneSubtitle(MilestoneItem item) {
    final t = item.title.toLowerCase();

    if (t.contains('brief')) {
      return 'Please read and acknowledge the campaign brief.';
    }

    if (t.contains('draft')) {
      // find myAward
      final awarded = (_campaign?['awardedInfluencers'] as List<dynamic>?) ?? [];
      final myAward = awarded.cast<Map<String, dynamic>?>().firstWhere(
            (a) => (a?['influencer']?.toString() ?? '') == widget.influencerId,
        orElse: () => null,
      );

      if (myAward != null) {
        final milestones = myAward['milestones'] ?? [];
        final draftMilestone = milestones.firstWhere(
              (m) => m['key'] == 'draft',
          orElse: () => null,
        );

        if (draftMilestone != null &&
            draftMilestone['submitted'] != null &&
            (draftMilestone['submitted'] as List).isNotEmpty) {
          final lastDraft =
          (draftMilestone['submitted'] as List).last as Map<String, dynamic>;
          final date = lastDraft['createdAt'];
          return "Last draft submitted on ${_formatDate(date)}";
        }
      }
      return 'Upload your draft for brand review.';
    }

    if (t.contains('post')) return 'Upload link to your live content.';
    if (t.contains('analytics')) return 'Submit analytics for review.';
    if (t.contains('barter')) return 'Barter fulfilled.';

    return 'Complete this milestone.';
  }


  Widget _buildCampaignDetailsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Campaign Details', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _detailRow('Platform', _campaign!['platform']?.toString() ?? '-'),
          _detailRow('Content Type', _campaign!['contentType']?.toString() ?? '-'),
          _detailRow('Incentive', (_campaign!['incentive'] ?? '').toString()),
          _detailRow('Duration',
              '${_campaign!['campaignDurationFrom'] ?? ''} to ${_campaign!['campaignDurationTo'] ?? ''}'),
        ]),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    final display = (value).toString().isEmpty ? '-' : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Utility: format ISO or date string into a friendly "dd MMM yyyy"
  String _formatDate(dynamic input) {
    if (input == null) return '-';
    final s = input.toString().trim();
    if (s.isEmpty) return '-';
    try {
      final dt = DateTime.tryParse(s);
      if (dt == null) return s; // If not ISO, return as-is
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final d = dt.day.toString().padLeft(2, '0');
      final m = months[dt.month - 1];
      final y = dt.year.toString();
      return '$d $m $y';
    } catch (_) {
      return s;
    }
  }

  void _showContractDialog(MilestoneItem milestone) {
    final awarded = (_campaign?['awardedInfluencers'] as List?) ?? [];
    final award = awarded.firstWhere(
          (a) => (a['influencer']?.toString() ?? '') == widget.influencerId,
      orElse: () => null,
    );

    if (award == null) return;

    final deliverables = Map<String, dynamic>.from(award['deliverables'] ?? {});
    final deadlines = Map<String, dynamic>.from(award['deadlines'] ?? {});
    final agreed = Map<String, dynamic>.from(award['agreed'] ?? {});
    final contract = Map<String, dynamic>.from(award['contract'] ?? {});

    showDialog(
      context: context,
      builder: (_) => CampaignContractDialog(
        contract: contract,
        deliverables: deliverables,
        deadlines: deadlines,
        agreed: agreed,
      ),
    );

  }


  Widget _milestoneTimelineTile(MilestoneItem item, bool isLast) {
    final isDone = item.status == 'submitted' || item.status == 'completed' || item.status == 'accepted' || item.status == 'acknowledged';
    final isPending = item.status == 'pending';

    IconData icon;
    Color iconColor;
    String subtitle = _milestoneSubtitle(item);

    if (item.key == 'contract') {
      icon = Icons.description;
    } else if (item.key == 'brief_ack') {
      icon = Icons.assignment_turned_in;
    } else if (item.key == 'draft') {
      icon = Icons.edit_document;
    } else if (item.key == 'post_live') {
      icon = Icons.public;
    } else if (item.key == 'analytics') {
      icon = Icons.bar_chart;
    } else {
      icon = Icons.check_circle_outline;
    }

    if (isDone) {
      iconColor = Colors.green;

      if (item.key == 'draft') {
        // 🔹 Find last submitted draft date
        final awarded = (_campaign?['awardedInfluencers'] as List<dynamic>?) ?? [];
        final myAward = awarded.cast<Map<String, dynamic>?>().firstWhere(
              (a) => (a?['influencer']?.toString() ?? '') == widget.influencerId,
          orElse: () => null,
        );

        if (myAward != null) {
          final milestones = myAward['milestones'] ?? [];
          final draftMilestone = milestones.firstWhere(
                (m) => m['key'] == 'draft',
            orElse: () => null,
          );

          if (draftMilestone != null &&
              draftMilestone['submitted'] != null &&
              (draftMilestone['submitted'] as List).isNotEmpty) {
            final lastDraft =
            (draftMilestone['submitted'] as List).last as Map<String, dynamic>;
            final date = lastDraft['createdAt'];
            subtitle = "Last draft submitted on ${_formatDate(date)}";
          } else {
            subtitle = "Draft submitted";
          }
        } else {
          subtitle = "Draft submitted";
        }
      } else {
        // default for others
        final date = item.dueAt['decidedAt'] ?? _campaign?['updatedAt'];
        subtitle = "Accepted on ${_formatDate(date)}";
      }
    }
    else if (isPending) {
      iconColor = Colors.orange;
    } else {
      iconColor = Colors.grey;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline
        Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Right milestone card with tap handling
        Expanded(
          child: GestureDetector(
            onTap: () async {
              if (item.key == 'contract') {
                _showContractDialog(item);
              } else if (item.key == 'brief_ack') {
                _showBriefDialog(item);
              }
              else if (item.key == 'draft') {
                // 🔹 Get myAward from awardedInfluencers
                final awarded = (_campaign?['awardedInfluencers'] as List<dynamic>?) ?? [];
                final myAward = awarded.cast<Map<String, dynamic>?>().firstWhere(
                      (a) => (a?['influencer']?.toString() ?? '') == widget.influencerId,
                  orElse: () => null,
                );

                // 🔹 Find draft milestone
                final milestones = myAward?['milestones'] ?? [];
                final draftMilestone = milestones.firstWhere(
                      (m) => m['key'] == 'draft',
                  orElse: () => null,
                );

                // 🔹 Extract submitted drafts list (safe cast)
                final drafts = draftMilestone != null
                    ? (draftMilestone['submitted'] as List<dynamic>)
                    .map((d) => Map<String, dynamic>.from(d as Map))
                    .toList()
                    : <Map<String, dynamic>>[];

                // 🔹 Open dialog
                final refresh = await showDialog(
                  context: context,
                  builder: (_) => ContentDraftDialog(
                    campaignId: _campaign!['_id'],
                    milestoneKey: item.key,
                    existingDrafts: drafts,
                  ),
                );

                if (refresh == true) {
                  _fetchCampaign(); // refresh after upload
                }
              }
              else if (item.key == 'post_live') {
                final awarded = (_campaign?['awardedInfluencers'] as List<dynamic>?) ?? [];
                final myAward = awarded.cast<Map<String, dynamic>?>().firstWhere(
                      (a) => (a?['influencer']?.toString() ?? '') == widget.influencerId,
                  orElse: () => null,
                );

                final milestones = myAward?['milestones'] ?? [];
                final postMilestone = milestones.firstWhere(
                      (m) => m['key'] == 'post_live',
                  orElse: () => null,
                );

                final posts = postMilestone != null
                    ? (postMilestone['submitted'] as List<dynamic>)
                    .map((d) => Map<String, dynamic>.from(d as Map))
                    .toList()
                    : <Map<String, dynamic>>[];

                final refresh = await showDialog(
                  context: context,
                  builder: (_) => PostLiveDialog(
                    campaignId: _campaign!['_id'],
                    milestoneKey: item.key,
                    existingPosts: posts,
                  ),
                );

                if (refresh == true) {
                  _fetchCampaign();
                }
              }

    else if (item.key == 'post_live') {
    // 🔹 Get myAward
    final awarded = (_campaign?['awardedInfluencers'] as List<dynamic>?) ?? [];
    final myAward = awarded.cast<Map<String, dynamic>?>().firstWhere(
    (a) => (a?['influencer']?.toString() ?? '') == widget.influencerId,
    orElse: () => null,
    );

    final milestones = myAward?['milestones'] ?? [];
    final postMilestone = milestones.firstWhere(
    (m) => m['key'] == 'post_live',
    orElse: () => null,
    );

    final posts = postMilestone != null
    ? (postMilestone['submitted'] as List<dynamic>)
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList()
        : <Map<String, dynamic>>[];

    final refresh = await showDialog(
    context: context,
    builder: (_) => PostLiveDialog(
    campaignId: _campaign!['_id'],
    milestoneKey: item.key,
    existingPosts: posts,
    ),
    );

    if (refresh == true) _fetchCampaign();
    }


    else if (item.key == 'analytics') {

    // 🔹 Get myAward
    final awarded = (_campaign?['awardedInfluencers'] as List<dynamic>?) ?? [];
    final myAward = awarded.cast<Map<String, dynamic>?>().firstWhere(
    (a) => (a?['influencer']?.toString() ?? '') == widget.influencerId,
    orElse: () => null,
    );

    final milestones = myAward?['milestones'] ?? [];
    final analyticsMilestone = milestones.firstWhere(
    (m) => m['key'] == 'analytics',
    orElse: () => null,
    );

    final analytics = analyticsMilestone != null
    ? (analyticsMilestone['submitted'] as List<dynamic>)
        .map((a) => Map<String, dynamic>.from(a as Map))
        .toList()
        : <Map<String, dynamic>>[];

    final refresh = await showDialog(
    context: context,
    builder: (_) => SubmitAnalyticsDialog(
    campaignId: _campaign!['_id'],
    milestoneKey: item.key,
    existingAnalytics: analytics,
    ),
    );

    if (refresh == true) _fetchCampaign();
    }



            },


            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPending ? Colors.green : Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(item.status.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }





}
