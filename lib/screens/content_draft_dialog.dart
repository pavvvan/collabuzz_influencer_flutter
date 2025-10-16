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
      backgroundColor: Colors.transparent, // Transparent background for depth
      insetPadding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard on tap outside
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
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

              // 🔹 Body
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    left: 20,
                    right: 20,
                    top: 16,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Existing Drafts
                      if (widget.existingDrafts.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.existingDrafts.reversed.length,
                          itemBuilder: (context, i) {
                            final d =
                            widget.existingDrafts.reversed.toList()[i];
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
                                  backgroundColor:
                                  Colors.deepPurple.withOpacity(0.1),
                                  child: const Icon(Icons.description,
                                      color: Colors.deepPurple),
                                ),
                                title: Text(
                                  d['notes'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (d['url'] != null &&
                                        d['url'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: GestureDetector(
                                          onTap: () async {
                                            final raw = d['url'].toString();
                                            final normalized = _normalizeUrl(raw);
                                            final uri = Uri.parse(normalized);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                  content: Text(
                                                      "Could not open $normalized")));
                                            }
                                          },
                                          child: Text(
                                            d['url'],
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              decoration:
                                              TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (d['createdAt'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "Uploaded on ${_formatDate(d['createdAt'])}",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54),
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
                            "No drafts uploaded yet.",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),

                      const SizedBox(height: 20),
                      const Divider(thickness: 1),
                      const SizedBox(height: 12),

                      // Upload Form
                      const Text(
                        "Upload New Draft",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: "Description",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: linkController,
                        decoration: InputDecoration(
                          labelText: "Content Link (image/video)",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _uploadDraft,
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
                              : const Text("Upload Draft",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
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
