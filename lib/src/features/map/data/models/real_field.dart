class RealField {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String status;
  final String? submittedBy;
  final DateTime createdAt;
  final String? city;
  final String? description;
  final String? surfaceType;
  final String? dimensions;

  RealField({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    required this.status,
    this.submittedBy,
    required this.createdAt,
    this.city,
    this.description,
    this.surfaceType,
    this.dimensions,
  });

  factory RealField.fromJson(Map<String, dynamic> json) {
    return RealField(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String,
      submittedBy: json['submitted_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      city: json['city'] as String?,
      description: json['description'] as String?,
      surfaceType: json['surface_type'] as String?,
      dimensions: json['dimensions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'status': status,
      'submitted_by': submittedBy,
      'created_at': createdAt.toIso8601String(),
      'city': city,
      'description': description,
      'surface_type': surfaceType,
      'dimensions': dimensions,
    };
  }

  // Display properties
  String get displayName => name;
  
  String get displayLocation => city ?? 'Portugal';
  
  String get displaySurfaceType {
    switch (surfaceType?.toLowerCase()) {
      case 'natural':
        return 'Relva Natural';
      case 'artificial':
        return 'Relva Sintética';
      case 'hybrid':
        return 'Relva Híbrida';
      default:
        return 'Tipo não especificado';
    }
  }

  String get displayDimensions => dimensions ?? 'Dimensões padrão';
  
  String get displayDescription => description ?? 'Campo de futebol bem mantido.';

  bool get isApproved => status == 'approved';
  
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  // Convert to the existing MapField format for compatibility
  Map<String, dynamic> toMapField() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'city': city,
      'surface_type': surfaceType,
      'dimensions': dimensions,
      'description': description,
      'photo_url': photoUrl,
    };
  }
}