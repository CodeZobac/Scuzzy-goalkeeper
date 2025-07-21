import 'package:flutter/material.dart';

class StadiumImageCard extends StatelessWidget {
  final String? stadiumName;
  final String? imageUrl;
  final double? distanceKm;
  final int? photoCount;
  final int? participantCount;
  final double height;
  final VoidCallback? onTap;

  const StadiumImageCard({
    super.key,
    this.stadiumName,
    this.imageUrl,
    this.distanceKm,
    this.photoCount,
    this.participantCount,
    this.height = 120,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF4CAF50),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          ),
        ),
        child: Stack(
          children: [
            // Stadium image
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Handle image loading error
                        },
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Center(
                      child: Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 40,
                      ),
                    )
                  : null,
            ),
            
            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            
            // Stadium info overlay
            if (stadiumName != null || distanceKm != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 60, // Leave space for indicators
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stadiumName != null)
                      Text(
                        stadiumName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (distanceKm != null)
                      Text(
                        '${distanceKm!.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            
            // Top right indicators
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Participant count indicator
                  if (participantCount != null && participantCount! > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+$participantCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  
                  // Photo count indicator
                  if (photoCount != null && photoCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$photoCount',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
}