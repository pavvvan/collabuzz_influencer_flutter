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
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 Header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFF512DA8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    left: 20,
                    right: 20,
                    top: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.existingAnalytics.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.existingAnalytics.reversed.length,
                          itemBuilder: (context, i) {
                            final d = widget.existingAnalytics.reversed.toList()[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  child: const Icon(Icons.bar_chart, color: Colors.blue),
                                ),
                                title: Text(
                                  d['url'] != null && d['url'].toString().isNotEmpty
                                      ? "Post: ${d['url']}"
                                      : "Analytics Entry",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // CTR & ER row
                                    Row(
                                      children: [
                                        if (d['ctr'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4, right: 12),
                                            child: Text(
                                              "CTR: ${d['ctr']}%",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.deepPurple,
                                              ),
                                            ),
                                          ),
                                        if (d['er'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              "ER: ${d['er']}%",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    if (d['notes'] != null && d['notes'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          d['notes'],
                                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                                        ),
                                      ),

                                    if (d['url'] != null && d['url'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: GestureDetector(
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
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),

                                    if (d['createdAt'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "Submitted on ${_formatDate(d['createdAt'])}",
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );

                          },
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "No analytics submitted yet.",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),

                      const SizedBox(height: 20),
                      const Divider(thickness: 1),
                      const SizedBox(height: 12),

                      const Text(
                        "Enter New Analytics",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 12),

                      _buildStyledField("Impressions", impressionsController,
                          "Total times your post was displayed."),
                      const SizedBox(height: 10),
                      _buildStyledField("Reach", reachController,
                          "Unique people who saw your post."),
                      const SizedBox(height: 10),
                      _buildStyledField("Engagements", engagementsController,
                          "Total likes, comments, shares, saves etc."),
                      const SizedBox(height: 10),
                      _buildStyledField("Clicks", clicksController,
                          "Number of people who clicked links."),
                      const SizedBox(height: 10),
                      _buildStyledField(
                          "CTR (%)", ctrController, "Click-through rate."),
                      const SizedBox(height: 10),
                      _buildStyledField(
                          "ER (%)", erController, "Engagement rate."),
                      const SizedBox(height: 10),
                      _buildStyledField(
                          "Post Link", postLinkController, "URL of your live post."),
                      const SizedBox(height: 20),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submitAnalytics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _loading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                              : const Text(
                            "Submit Analytics",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStyledField(
      String label, TextEditingController controller, String description) {
    return TextField(
      controller: controller,
      keyboardType: label.contains("Link")
          ? TextInputType.url
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
