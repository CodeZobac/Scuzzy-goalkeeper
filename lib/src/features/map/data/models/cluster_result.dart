import 'package:latlong2/latlong.dart';
import 'cluster_point.dart';

/// Result of clustering operation containing clusters and individual points
class ClusterResult {
  final List<Cluster> clusters;
  final List<ClusterPoint> singlePoints;

  const ClusterResult({
    required this.clusters,
    required this.singlePoints,
  });

  /// Total number of points (clustered + individual)
  int get totalPoints => 
      clusters.fold(0, (sum, cluster) => sum + cluster.size) + singlePoints.length;

  /// Get all points as a flat list
  List<ClusterPoint> get allPoints {
    final List<ClusterPoint> points = [];
    
    // Add all clustered points
    for (final cluster in clusters) {
      points.addAll(cluster.points);
    }
    
    // Add individual points
    points.addAll(singlePoints);
    
    return points;
  }

  /// Check if clustering result is empty
  bool get isEmpty => clusters.isEmpty && singlePoints.isEmpty;

  /// Check if clustering result has content
  bool get isNotEmpty => !isEmpty;

  /// Get statistics about the clustering result
  ClusterStats get stats {
    final Map<ClusterPointType, int> typeCounts = {};
    
    // Count types in clusters
    for (final cluster in clusters) {
      for (final point in cluster.points) {
        typeCounts[point.type] = (typeCounts[point.type] ?? 0) + 1;
      }
    }
    
    // Count types in individual points
    for (final point in singlePoints) {
      typeCounts[point.type] = (typeCounts[point.type] ?? 0) + 1;
    }
    
    return ClusterStats(
      totalClusters: clusters.length,
      totalIndividualPoints: singlePoints.length,
      totalPoints: totalPoints,
      typeCounts: typeCounts,
      largestClusterSize: clusters.isEmpty ? 0 : 
          clusters.map((c) => c.size).reduce((a, b) => a > b ? a : b),
    );
  }

  @override
  String toString() {
    return 'ClusterResult{clusters: ${clusters.length}, singlePoints: ${singlePoints.length}, total: $totalPoints}';
  }
}

/// Represents a cluster of related points
class Cluster {
  final LatLng center;
  final List<ClusterPoint> points;
  final int size;
  final String? id;

  Cluster({
    required this.center,
    required this.points,
    int? size,
    this.id,
  }) : size = size ?? points.length;

  /// Get the dominant point type in this cluster
  ClusterPointType get dominantType {
    if (points.isEmpty) return ClusterPointType.field;
    
    final Map<ClusterPointType, int> typeCounts = {};
    for (final point in points) {
      typeCounts[point.type] = (typeCounts[point.type] ?? 0) + 1;
    }
    
    return typeCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get the highest priority point in this cluster (for representing the cluster)
  ClusterPoint get representativePoint {
    if (points.isEmpty) {
      throw StateError('Cannot get representative point from empty cluster');
    }
    
    return points.reduce((a, b) => a.priority > b.priority ? a : b);
  }

  /// Get breakdown of point types in this cluster
  Map<ClusterPointType, int> get typeBreakdown {
    final Map<ClusterPointType, int> breakdown = {};
    for (final point in points) {
      breakdown[point.type] = (breakdown[point.type] ?? 0) + 1;
    }
    return breakdown;
  }

  /// Get display summary for this cluster
  String get displaySummary {
    final breakdown = typeBreakdown;
    final List<String> parts = [];
    
    for (final entry in breakdown.entries) {
      if (entry.value == 1) {
        parts.add('1 ${entry.key.displayName}');
      } else {
        parts.add('${entry.value} ${entry.key.pluralDisplayName}');
      }
    }
    
    if (parts.isEmpty) return 'Cluster vazio';
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) return '${parts[0]} e ${parts[1]}';
    
    return '${parts.sublist(0, parts.length - 1).join(', ')} e ${parts.last}';
  }

  /// Check if cluster contains a specific point type
  bool containsType(ClusterPointType type) {
    return points.any((point) => point.type == type);
  }

  /// Get all points of a specific type
  List<ClusterPoint> pointsOfType(ClusterPointType type) {
    return points.where((point) => point.type == type).toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cluster &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          center == other.center &&
          size == other.size;

  @override
  int get hashCode => id?.hashCode ?? (center.hashCode ^ size.hashCode);

  @override
  String toString() {
    return 'Cluster{center: $center, size: $size, types: ${typeBreakdown.keys.toList()}}';
  }
}

/// Statistics about a clustering result
class ClusterStats {
  final int totalClusters;
  final int totalIndividualPoints;
  final int totalPoints;
  final Map<ClusterPointType, int> typeCounts;
  final int largestClusterSize;

  const ClusterStats({
    required this.totalClusters,
    required this.totalIndividualPoints,
    required this.totalPoints,
    required this.typeCounts,
    required this.largestClusterSize,
  });

  /// Get count for a specific type
  int getCountForType(ClusterPointType type) {
    return typeCounts[type] ?? 0;
  }

  /// Check if stats are empty
  bool get isEmpty => totalPoints == 0;

  @override
  String toString() {
    return 'ClusterStats{clusters: $totalClusters, individual: $totalIndividualPoints, total: $totalPoints}';
  }
}
