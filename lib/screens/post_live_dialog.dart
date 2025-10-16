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
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    const Text(
                      "Post Live",
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

              // 🔹 Scrollable Body
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
                      // Existing posts
                      if (widget.existingPosts.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.existingPosts.reversed.length,
                          itemBuilder: (context, i) {
                            final d = widget.existingPosts.reversed.toList()[i];
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
                                  Colors.green.withOpacity(0.1),
                                  child: const Icon(Icons.link,
                                      color: Colors.green),
                                ),
                                title: GestureDetector(
                                  onTap: () async {
                                    final uri =
                                    Uri.parse(_normalizeUrl(d['url'] ?? ''));
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Text(
                                    d['url'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (d['notes'] != null &&
                                        d['notes'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          d['notes'],
                                          style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 13),
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
                            "No post links submitted yet.",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),

                      const SizedBox(height: 20),
                      const Divider(thickness: 1),
                      const SizedBox(height: 12),

                      const Text(
                        "Upload New Post Link",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: linkController,
                        decoration: InputDecoration(
                          labelText: "Content Link (Instagram/YouTube/etc.)",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: "Notes (optional)",
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
                          onPressed: _loading ? null : _uploadPostLive,
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
                            "Submit",
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
