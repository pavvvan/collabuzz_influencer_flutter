import 'package:flutter/material.dart';

class CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback? onTap;

  const CampaignCard({
    Key? key,
    required this.campaign,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String platform = (campaign['platform'] ?? '').toLowerCase();
    String platformIcon = platform == 'instagram'
        ? 'assets/instagram.png'
        : platform == 'youtube'
        ? 'assets/youtube.png'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    campaign['CampaignPhoto'] ?? '',
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 90,
                      width: 90,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Campaign Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign['campaignName'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis, // 👈 adds ellipsis
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),


                      Text(
                        campaign['brandName'] ?? '',
                        style: const TextStyle(
                            color: Colors.purple, fontSize: 13),
                      ),

                      Text(
                        campaign['influencerCategory'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        campaign['campaignDurationFrom']+"-"+campaign['campaignDurationTo'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Campaign Type Label
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: campaign['campaignType'] == 'barter'
                        ? Colors.green[50]
                        : Colors.purple[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    campaign['campaignType'] ?? '',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Platform Icon (overflow top-left)
          if (platformIcon.isNotEmpty)
            Positioned(
              top: 5,
              left: -2,
              child: Image.asset(platformIcon, height: 20, width: 20),
            ),
        ],
      ),
    );
  }
}
