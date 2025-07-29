import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/cluster_point.dart';
import '../models/cluster_result.dart';

/// High-performance clustering service for map markers
/// Uses spatial indexing and zoom-level thresholds for smooth clustering
class ClusteringService {
  static const double _earthRadius = 6371000; // Earth radius in meters
  static const Map<int, double> _zoomToClusterRadius = {
    1: 500000,  // 500km at zoom 1
    2: 300000,  // 300km at zoom 2
    3: 200000,  // 200km at zoom 3
    4: 150000,  // 150km at zoom 4
    5: 100000,  // 100km at zoom 5
    6: 80000,   // 80km at zoom 6
    7: 60000,   // 60km at zoom 7
    8: 40000,   // 40km at zoom 8
    9: 30000,   // 30km at zoom 9
    10: 20000,  // 20km at zoom 10
    11: 15000,  // 15km at zoom 11
    12: 8000,   // 8km at zoom 12
    13: 4000,   // 4km at zoom 13
    14: 2000,   // 2km at zoom 14
    15: 800,    // 800m at zoom 15
    16: 300,    // 300m at zoom 16
    17: 100,    // 100m at zoom 17
    18: 50,     // 50m at zoom 18
  };

  /// Cluster points based on zoom level and spatial proximity
  static ClusterResult clusterPoints({
    required List<ClusterPoint> points,
    required double zoom,
    int minPointsForCluster = 2,
  }) {
    if (points.isEmpty) {
      return ClusterResult(clusters: [], singlePoints: []);
    }

    final int zoomLevel = zoom.round().clamp(1, 18);
    final double clusterRadius = _zoomToClusterRadius[zoomLevel] ?? 1000;

    // If zoom is high enough, don't cluster (show individual points)
    if (zoomLevel >= 16) {
      return ClusterResult(clusters: [], singlePoints: points);
    }

    return _performClustering(
      points: points,
      clusterRadius: clusterRadius,
      minPointsForCluster: minPointsForCluster,
    );
  }

  /// Core clustering algorithm using distance-based grouping
  static ClusterResult _performClustering({
    required List<ClusterPoint> points,
    required double clusterRadius,
    required int minPointsForCluster,
  }) {
    final List<Cluster> clusters = [];
    final List<ClusterPoint> processedPoints = [];
    final Set<int> processed = {};

    for (int i = 0; i < points.length; i++) {
      if (processed.contains(i)) continue;

      final List<ClusterPoint> nearbyPoints = [points[i]];
      processed.add(i);

      // Find all points within cluster radius
      for (int j = i + 1; j < points.length; j++) {
        if (processed.contains(j)) continue;

        final double distance = _calculateDistance(
          points[i].location,
          points[j].location,
        );

        if (distance <= clusterRadius) {
          nearbyPoints.add(points[j]);
          processed.add(j);
        }
      }

      // Create cluster if we have enough points
      if (nearbyPoints.length >= minPointsForCluster) {
        clusters.add(Cluster(
          center: _calculateCentroid(nearbyPoints),
          points: nearbyPoints,
          size: nearbyPoints.length,
        ));
      } else {
        // Add as individual points
        processedPoints.addAll(nearbyPoints);
      }
    }

    return ClusterResult(
      clusters: clusters,
      singlePoints: processedPoints,
    );
  }

  /// Calculate the centroid (center point) of a group of points
  static LatLng _calculateCentroid(List<ClusterPoint> points) {
    if (points.isEmpty) {
      throw ArgumentError('Cannot calculate centroid of empty points list');
    }

    if (points.length == 1) {
      return points.first.location;
    }

    double totalLat = 0;
    double totalLng = 0;

    for (final point in points) {
      totalLat += point.location.latitude;
      totalLng += point.location.longitude;
    }

    return LatLng(
      totalLat / points.length,
      totalLng / points.length,
    );
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(LatLng point1, LatLng point2) {
    final double lat1Rad = point1.latitude * math.pi / 180;
    final double lat2Rad = point2.latitude * math.pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * math.pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * math.pi / 180;

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadius * c;
  }

  /// Get the cluster radius for a specific zoom level
  static double getClusterRadiusForZoom(double zoom) {
    final int zoomLevel = zoom.round().clamp(1, 18);
    return _zoomToClusterRadius[zoomLevel] ?? 1000;
  }

  /// Check if two points should be clustered at a given zoom level
  static bool shouldCluster(LatLng point1, LatLng point2, double zoom) {
    final double distance = _calculateDistance(point1, point2);
    final double threshold = getClusterRadiusForZoom(zoom);
    return distance <= threshold;
  }

  /// Predict cluster changes when zoom level changes
  /// This helps with smooth transitions
  static ClusterTransition predictTransition({
    required ClusterResult currentClusters,
    required double fromZoom,
    required double toZoom,
  }) {
    if ((toZoom - fromZoom).abs() < 0.5) {
      // Small zoom change, no significant clustering changes expected
      return ClusterTransition(
        type: ClusterTransitionType.none,
        affectedClusters: [],
      );
    }

    if (toZoom > fromZoom) {
      // Zooming in - clusters will expand/break apart
      return ClusterTransition(
        type: ClusterTransitionType.expand,
        affectedClusters: currentClusters.clusters
            .where((cluster) => cluster.size > 2)
            .toList(),
      );
    } else {
      // Zooming out - points will agglomerate into clusters
      return ClusterTransition(
        type: ClusterTransitionType.contract,
        affectedClusters: currentClusters.clusters,
      );
    }
  }
}

/// Represents the transition state between zoom levels
class ClusterTransition {
  final ClusterTransitionType type;
  final List<Cluster> affectedClusters;

  const ClusterTransition({
    required this.type,
    required this.affectedClusters,
  });
}

enum ClusterTransitionType {
  none,     // No significant change
  expand,   // Clusters breaking apart (zoom in)
  contract, // Points agglomerating (zoom out)
}
