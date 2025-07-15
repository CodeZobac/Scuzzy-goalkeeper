import 'dart:convert';

class Field {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String status;
  final String? submittedBy;
  final DateTime createdAt;

  Field({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    required this.status,
    this.submittedBy,
    required this.createdAt,
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
    };
  }

  factory Field.fromMap(Map<String, dynamic> map) {
    return Field(
      id: map['id'],
      name: map['name'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      photoUrl: map['photo_url'],
      status: map['status'],
      submittedBy: map['submitted_by'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Field.fromJson(String source) =>
      Field.fromMap(json.decode(source));

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
}
