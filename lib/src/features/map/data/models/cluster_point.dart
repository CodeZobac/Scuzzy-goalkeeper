import 'package:latlong2/latlong.dart';

/// Represents a point that can be clustered on the map
/// Supports fields, goalkeepers, and other map entities
class ClusterPoint {
  final String id;
  final LatLng location;
  final ClusterPointType type;
  final Map<String, dynamic> data;
  final int priority; // Higher priority points are preferred for cluster centers

  const ClusterPoint({
    required this.id,
    required this.location,
    required this.type,
    required this.data,
    this.priority = 0,
  });

  /// Create a cluster point from a field
  factory ClusterPoint.fromField(dynamic field) {
    return ClusterPoint(
      id: 'field_${field.id}',
      location: LatLng(field.latitude, field.longitude),
      type: ClusterPointType.field,
      data: {
        'field': field,
        'name': field.name,
        'city': field.city,
        'surface': field.surfaceType,
        'dimensions': field.dimensions,
      },
      priority: 2, // Fields have higher priority
    );
  }

  /// Create a cluster point from a goalkeeper
  factory ClusterPoint.fromGoalkeeper(dynamic goalkeeper, LatLng location) {
    return ClusterPoint(
      id: 'goalkeeper_${goalkeeper.id}',
      location: location,
      type: ClusterPointType.goalkeeper,
      data: {
        'goalkeeper': goalkeeper,
        'name': goalkeeper.name ?? 'Unknown Goalkeeper',
        'city': goalkeeper.city,
        'rating': goalkeeper.displayOverallRating,
        'verified': goalkeeper.isVerified,
      },
      priority: 3, // Goalkeepers have highest priority
    );
  }

  /// Create a cluster point from a player
  factory ClusterPoint.fromPlayer(Map<String, dynamic> player, LatLng location) {
    return ClusterPoint(
      id: 'player_${player['id'] ?? DateTime.now().millisecondsSinceEpoch}',
      location: location,
      type: ClusterPointType.player,
      data: {
        'player': player,
        'name': player['name'] ?? 'Player',
      },
      priority: 1, // Players have lowest priority
    );
  }

  /// Get display name for this point
  String get displayName {
    switch (type) {
      case ClusterPointType.field:
        return data['name'] ?? 'Football Field';
      case ClusterPointType.goalkeeper:
        return data['name'] ?? 'Goalkeeper';
      case ClusterPointType.player:
        return data['name'] ?? 'Player';
    }
  }

  /// Get color for this point type
  static const Map<ClusterPointType, int> _typeColors = {
    ClusterPointType.field: 0xFF4CAF50,      // Green for fields
    ClusterPointType.goalkeeper: 0xFFFF9800, // Orange for goalkeepers
    ClusterPointType.player: 0xFF2196F3,     // Blue for players
  };

  int get color => _typeColors[type] ?? 0xFF000000;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClusterPoint &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ClusterPoint{id: $id, type: $type, location: $location}';
  }
}

/// Types of points that can be clustered
enum ClusterPointType {
  field,
  goalkeeper,
  player,
}

/// Extension to get user-friendly names for point types
extension ClusterPointTypeExtension on ClusterPointType {
  String get displayName {
    switch (this) {
      case ClusterPointType.field:
        return 'Campo';
      case ClusterPointType.goalkeeper:
        return 'Guarda-redes';
      case ClusterPointType.player:
        return 'Jogador';
    }
  }

  String get pluralDisplayName {
    switch (this) {
      case ClusterPointType.field:
        return 'Campos';
      case ClusterPointType.goalkeeper:
        return 'Guarda-redes';
      case ClusterPointType.player:
        return 'Jogadores';
    }
  }
}
