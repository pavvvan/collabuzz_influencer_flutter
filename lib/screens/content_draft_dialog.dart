import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/dart/campaign_service.dart';

class ContentDraftDialog extends StatefulWidget {
  final String campaignId;
  final String milestoneKey;
  final List<Map<String, dynamic>> existingDrafts;

  const ContentDraftDialog({
    Key? key,
    required this.campaignId,
    required this.milestoneKey,
    required this.existingDrafts,
  }) : super(key: key);

  @override
  State<ContentDraftDialog> createState() => _ContentDraftDialogState();
}

class _ContentDraftDialogState extends State<ContentDraftDialog> {
  final TextEditingController descController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔹 Purple Header with Close Button
          Container(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  "Content Drafts",
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

          // 🔹 White Content Area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Existing drafts list
                // Existing drafts list
                if (widget.existingDrafts.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.existingDrafts.reversed.length,
                      itemBuilder: (context, i) {
                        final d = widget.existingDrafts.reversed.toList()[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.description,
                                color: Colors.deepPurple),
                            title: Text(d['notes'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (d['url'] != null && d['url'].toString().isNotEmpty)
                                  GestureDetector(
                                    onTap: () async {
                                      final raw = d['url'].toString();
                                      final normalized = _normalizeUrl(raw);
                                      final uri = Uri.parse(normalized);

                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri,
                                            mode: LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Could not open $normalized")),
                                        );
                                      }
                                    },
                                    child: Text(
                                      d['url'],
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                if (d['createdAt'] != null)
                                  Text(
                                    "Uploaded on ${_formatDate(d['createdAt'])}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Text("No drafts uploaded yet.",
                      style: TextStyle(color: Colors.black54)),

                const SizedBox(height: 16),
                const Divider(),

                // Upload new draft form
                const Text("Upload New Draft",
                    style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: "Content Link (image/video)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _uploadDraft,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                            : const Text("Upload Draft",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDraft() async {
    if (descController.text.isEmpty || linkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final resp = await CampaignService().uploadDraft(
        campaignId: widget.campaignId,
        milestoneKey: widget.milestoneKey,
        description: descController.text, // ✅ "notes"
        link: linkController.text, // ✅ "url"
      );

      if (resp['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? "Draft uploaded!")),
        );
        Navigator.pop(context, true); // return true to refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? "Upload failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading draft: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatDate(dynamic input) {
    if (input == null) return '-';
    try {
      final dtUtc = DateTime.tryParse(input.toString());
      if (dtUtc == null) return input.toString();

      // Convert UTC → IST (+5:30)
      final dt = dtUtc.toLocal().add(const Duration(hours: 5, minutes: 30));

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year.toString();

      // Time in hh:mm AM/PM
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? "PM" : "AM";

      return "$day $month $year, $hour:$minute $ampm IST";
    } catch (_) {
      return input.toString();
    }
  }


  String _normalizeUrl(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      return url;
    }
    return "https://$url"; // default prepend
  }
}
