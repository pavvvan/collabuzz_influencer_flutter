import 'package:flutter/material.dart';

class CampaignContractDialog extends StatelessWidget {
  final Map<String, dynamic> contract;
  final Map<String, dynamic> deliverables;
  final Map<String, dynamic> deadlines;
  final Map<String, dynamic> agreed;

  const CampaignContractDialog({
    Key? key,
    required this.contract,
    required this.deliverables,
    required this.deadlines,
    required this.agreed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // 🔹 Header
            Container(
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    "Campaign Contract",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                padding: const EdgeInsets.all(18),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section(
                        "Deliverables",
                        [
                          "Posts: ${deliverables['postCount'] ?? 0}",
                          "Stories: ${deliverables['storyCount'] ?? 0}",
                          "Videos: ${deliverables['videoCount'] ?? 0}",
                          "Reels: ${deliverables['reelCount'] ?? 0}",
                        ],
                      ),
                      _divider(),
                      _section(
                        "Deadlines",
                        [
                          "Draft Due: ${_formatDate(deadlines['draftDueAt'])}",
                          "Go-Live Due: ${_formatDate(deadlines['goLiveDueAt'])}",
                          "Analytics Due: ${_formatDate(deadlines['analyticsDueAt'])}",
                        ],
                      ),
                      _divider(),
                      _section(
                        "Agreed Terms",
                        [
                          "Currency: ${agreed['currency'] ?? '-'}",
                          if ((agreed['barterNotes'] ?? '').toString().isNotEmpty)
                            "Notes: ${agreed['barterNotes']}"
                        ],
                      ),
                      _divider(),
                      _section(
                        "Contract Info",
                        [
                          "Version: ${contract['version'] ?? '-'}",
                          "Status: ${contract['status'] ?? '-'}",
                          if (contract['brandSignedAt'] != null)
                            "Brand Signed On: ${_formatDate(contract['brandSignedAt'])}",
                          if (contract['influencerSignedAt'] != null)
                            "Influencer Signed On: ${_formatDate(contract['influencerSignedAt'])}",
                        ],
                      ),
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

  Widget _section(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black)),
          const SizedBox(height: 8),
          ...items.where((e) => e.trim().isNotEmpty).map(
                (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Text(
                e,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      color: Colors.grey.shade300,
      thickness: 1,
      height: 20,
    );
  }

  String _formatDate(dynamic input) {
    if (input == null) return "-";
    try {
      final dt = DateTime.tryParse(input.toString());
      if (dt == null) return input.toString();
      final ist = dt.toLocal().add(const Duration(hours: 5, minutes: 30));
      return "${ist.day}-${ist.month}-${ist.year} "
          "${ist.hour.toString().padLeft(2, '0')}:${ist.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return input.toString();
    }
  }
}
