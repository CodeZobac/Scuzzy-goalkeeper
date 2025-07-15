import 'dart:convert';

class MapField {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String status;
  final String? submittedBy;
  final DateTime createdAt;
  final String? description;
  final String? surfaceType;
  final String? dimensions;

  MapField({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    required this.status,
    this.submittedBy,
    required this.createdAt,
    this.description,
    this.surfaceType,
    this.dimensions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'status': status,
      'submitted_by': submittedBy,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'surface_type': surfaceType,
      'dimensions': dimensions,
    };
  }

  factory MapField.fromMap(Map<String, dynamic> map) {
    return MapField(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      photoUrl: map['photo_url'],
      status: map['status'] ?? 'pending',
      submittedBy: map['submitted_by'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      description: map['description'],
      surfaceType: map['surface_type'],
      dimensions: map['dimensions'],
    );
  }

  String toJson() => json.encode(toMap());

  factory MapField.fromJson(String source) =>
      MapField.fromMap(json.decode(source));

  // Helper methods
  String get displayName => name;
  
  String get displayStatus {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'approved':
        return 'Aprovado';
      case 'rejected':
        return 'Rejeitado';
      default:
        return status;
    }
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  String get displayLocation {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  String get displaySurfaceType {
    switch (surfaceType) {
      case 'natural':
        return 'Natural';
      case 'artificial':
        return 'Artificial';
      case 'hybrid':
        return 'Híbrido';
      default:
        return surfaceType ?? 'N/A';
    }
  }

  MapField copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? status,
    String? submittedBy,
    DateTime? createdAt,
    String? description,
    String? surfaceType,
    String? dimensions,
  }) {
    return MapField(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      submittedBy: submittedBy ?? this.submittedBy,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      surfaceType: surfaceType ?? this.surfaceType,
      dimensions: dimensions ?? this.dimensions,
    );
  }
}
