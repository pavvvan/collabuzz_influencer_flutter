import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/dart/campaign_service.dart';

class PostLiveDialog extends StatefulWidget {
  final String campaignId;
  final String milestoneKey;
  final List<Map<String, dynamic>> existingPosts;

  const PostLiveDialog({
    Key? key,
    required this.campaignId,
    required this.milestoneKey,
    required this.existingPosts,
  }) : super(key: key);

  @override
  State<PostLiveDialog> createState() => _PostLiveDialogState();
}

class _PostLiveDialogState extends State<PostLiveDialog> {
  final TextEditingController linkController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text("Post Live",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Body
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.existingPosts.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.existingPosts.length,
                      itemBuilder: (context, i) {
                        final d = widget.existingPosts[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.link, color: Colors.green),
                            title: GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(_normalizeUrl(d['url']));
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Text(
                                d['url'] ?? '',
                                style: const TextStyle(
                                    color: Colors.blue, decoration: TextDecoration.underline),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (d['notes'] != null && d['notes'].toString().isNotEmpty)
                                  Text("Notes: ${d['notes']}"),
                                if (d['createdAt'] != null)
                                  Text("Uploaded on ${_formatDate(d['createdAt'])}",
                                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Text("No post links submitted yet.",
                      style: TextStyle(color: Colors.black54)),

                const SizedBox(height: 16),
                const Divider(),

                const Text("Upload New Post Link",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: "Content Link (Instagram/YouTube/etc.)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: "Notes (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _loading ? null : _uploadPostLive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text("Submit", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPostLive() async {
    if (linkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter link")),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await CampaignService().uploadPostLive(
        campaignId: widget.campaignId,
        milestoneKey: widget.milestoneKey,
        link: linkController.text,
        description: notesController.text,
      );

      if (resp['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? "Post submitted!")),
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

  String _normalizeUrl(String url) =>
      url.startsWith("http") ? url : "https://$url";

  String _formatDate(String input) {
    final dt = DateTime.tryParse(input)?.toLocal().add(const Duration(hours: 5, minutes: 30));
    if (dt == null) return input;
    return "${dt.day}-${dt.month}-${dt.year} ${dt.hour}:${dt.minute}";
  }
}
