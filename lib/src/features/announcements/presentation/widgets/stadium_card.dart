import 'package:flutter/material.dart';
import '../../../../shared/widgets/location_aware_distance.dart';

class StadiumCard extends StatelessWidget {
  final String stadiumName;
  final String? imageUrl;
  final double? distance;
  final int? photoCount;
  final VoidCallback onMapTap;
  final double? fieldLatitude;
  final double? fieldLongitude;
  final String? fieldPhotoUrl;

  const StadiumCard({
    super.key,
    required this.stadiumName,
    this.imageUrl,
    this.distance,
    this.photoCount,
    required this.onMapTap,
    this.fieldLatitude,
    this.fieldLongitude,
    this.fieldPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stadium name and distance
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stadiumName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // Use location-aware distance if coordinates are available,
                      // otherwise show "Sem imagens de momento" if no location access
                      LocationAwareDistance(
                        fieldLatitude: fieldLatitude,
                        fieldLongitude: fieldLongitude,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        suffix: ' km de distância',
                        child: const Text(
                          'Sem imagens de momento',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Map button
                Material(

                  color: Colors.white.withOpacity(0.2),

                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onMapTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mostrar no mapa',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stadium image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),

                color: Colors.white.withOpacity(0.1),

              ),
              child: Stack(
                children: [
                  // Stadium image - use field photo if available, otherwise fallback to imageUrl
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: (fieldPhotoUrl != null || imageUrl != null)
                          ? DecorationImage(
                              image: NetworkImage(fieldPhotoUrl ?? imageUrl!),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                // Handle image loading error
                              },
                            )
                          : null,
                    ),
                    child: (fieldPhotoUrl == null && imageUrl == null)
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports_soccer,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Sem imagens de momento',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                  
                  // Remove the hardcoded photo count indicator
                  // Photo count is no longer displayed as requested
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
