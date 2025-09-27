import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/dart/campaign_service.dart';

class SubmitAnalyticsDialog extends StatefulWidget {
  final String campaignId;
  final String milestoneKey;
  final List<Map<String, dynamic>> existingAnalytics; // <-- pass milestone.submitted[]

  const SubmitAnalyticsDialog({
    Key? key,
    required this.campaignId,
    required this.milestoneKey,
    required this.existingAnalytics,
  }) : super(key: key);

  @override
  State<SubmitAnalyticsDialog> createState() => _SubmitAnalyticsDialogState();
}

class _SubmitAnalyticsDialogState extends State<SubmitAnalyticsDialog> {
  final TextEditingController impressionsController = TextEditingController();
  final TextEditingController reachController = TextEditingController();
  final TextEditingController engagementsController = TextEditingController();
  final TextEditingController clicksController = TextEditingController();
  final TextEditingController ctrController = TextEditingController();
  final TextEditingController erController = TextEditingController();
  final TextEditingController postLinkController = TextEditingController();

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // 🔹 Header
            Container(
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    "Submit Analytics",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 🔹 Body
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.existingAnalytics.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.existingAnalytics.length,
                          itemBuilder: (context, i) {
                            final d = widget.existingAnalytics[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const Icon(Icons.bar_chart, color: Colors.blue),
                                title: Text(
                                  "Post: ${d['url'] ?? '-'}",
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (d['notes'] != null)
                                      Text(
                                        d['notes'],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    if (d['url'] != null &&
                                        d['url'].toString().isNotEmpty)
                                      GestureDetector(
                                        onTap: () async {
                                          final uri = Uri.parse(_normalizeUrl(d['url']));
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        child: Text(
                                          d['url'],
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    if (d['createdAt'] != null)
                                      Text(
                                        "Submitted on ${_formatDate(d['createdAt'])}",
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.black54),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      else
                        const Text("No analytics submitted yet.",
                            style: TextStyle(color: Colors.black54)),

                      const SizedBox(height: 16),
                      const Divider(),
                      const Text("Enter New Analytics",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 8),

                      _buildFieldWithInfo("Impressions", impressionsController,
                          "Total times your post was displayed."),
                      const SizedBox(height: 10),
                      _buildFieldWithInfo("Reach", reachController,
                          "Unique people who saw your post."),
                      const SizedBox(height: 10),
                      _buildFieldWithInfo("Engagements", engagementsController,
                          "Total likes, comments, shares, saves etc."),
                      const SizedBox(height: 10),
                      _buildFieldWithInfo("Clicks", clicksController,
                          "Number of people who clicked links in the post."),
                      const SizedBox(height: 10),
                      _buildFieldWithInfo("CTR (%)", ctrController, "Click-through rate."),
                      const SizedBox(height: 10),
                      _buildFieldWithInfo("ER (%)", erController, "Engagement rate."),
                      const SizedBox(height: 10),
                      _buildFieldWithInfo("Post Link", postLinkController,
                          "URL of your live post."),
                      const SizedBox(height: 20),

                      // 🔹 Full-width submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submitAnalytics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                              : const Text("Submit Analytics",
                              style: TextStyle(color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Helper for fields with info icon that opens a popup
  Widget _buildFieldWithInfo(
      String label, TextEditingController controller, String description) {
    return TextField(
      controller: controller,
      keyboardType: label.contains("Link")
          ? TextInputType.url
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.grey),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(label),
                content: Text(description),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 🔹 Validation & API call
  Future<void> _submitAnalytics() async {
    if (impressionsController.text.isEmpty ||
        reachController.text.isEmpty ||
        engagementsController.text.isEmpty ||
        postLinkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Please fill Impressions, Reach, Engagements & Post Link")),
      );
      return;
    }

    if (!postLinkController.text.startsWith("http")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post Link must start with http/https")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final resp = await CampaignService().submitAnalytics(
        campaignId: widget.campaignId,
        milestoneKey: widget.milestoneKey,
        impressions: int.tryParse(impressionsController.text) ?? 0,
        reach: int.tryParse(reachController.text) ?? 0,
        engagements: int.tryParse(engagementsController.text) ?? 0,
        clicks: int.tryParse(clicksController.text) ?? 0,
        ctr: double.tryParse(ctrController.text) ?? 0,
        er: double.tryParse(erController.text) ?? 0,
        postLink: postLinkController.text,
      );

      if (resp['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? "Analytics submitted!")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? "Failed")),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  String _normalizeUrl(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      return url;
    }
    return "https://$url";
  }

  String _formatDate(dynamic input) {
    try {
      final dt = DateTime.tryParse(input.toString());
      if (dt == null) return input.toString();
      final local = dt.toLocal().add(const Duration(hours: 5, minutes: 30));
      return "${local.day}-${local.month}-${local.year} ${local.hour}:${local.minute}";
    } catch (_) {
      return input.toString();
    }
  }
}
