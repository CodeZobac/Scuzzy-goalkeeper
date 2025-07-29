import 'dart:convert';
import 'dart:math';

import 'package:goalkeeper/src/features/user_profile/data/services/level_service.dart';

class UserProfile {
  final String id;
  String name;
  String? gender;
  String? city;
  DateTime? birthDate;
  String? club;
  String? nationality;
  String? country;
  bool isGoalkeeper;
  double? pricePerGame;
  List<int>? reflexes;
  List<int>? positioning;
  List<int>? distribution;
  List<int>? communication;
  bool profileCompleted;
  DateTime createdAt;
  int gamesPlayed;
  double? latitude;
  double? longitude;

  UserProfile({
    required this.id,
    required this.createdAt,
    required this.name,
    this.gender,
    this.city,
    this.birthDate,
    this.club,
    this.nationality,
    this.country,
    this.isGoalkeeper = false,
    this.pricePerGame,
    this.reflexes,
    this.positioning,
    this.distribution,
    this.communication,
    this.profileCompleted = false,
    this.gamesPlayed = 0,
    this.latitude,
    this.longitude,
  });

  int get level => LevelService().getLevelFromGames(gamesPlayed);

  void addGames(int count) {
    gamesPlayed += count;
  }

  double getOverallRating() {
    final allRatings = [
      ...?reflexes,
      ...?positioning,
      ...?distribution,
      ...?communication,
    ];

    if (allRatings.isEmpty) {
      return 0.0;
    }

    return allRatings.reduce((a, b) => a + b) / allRatings.length;
  }

  /// Calculate distance to another user in kilometers
  double? distanceTo(UserProfile other) {
    if (latitude == null || longitude == null || 
        other.latitude == null || other.longitude == null) {
      return null;
    }
    
    return _calculateDistance(latitude!, longitude!, other.latitude!, other.longitude!);
  }

  /// Haversine formula to calculate distance between two points
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * 
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Check if user has location data
  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'city': city,
      'birth_date': birthDate?.toIso8601String(),
      'club': club,
      'nationality': nationality,
      'country': country,
      'is_goalkeeper': isGoalkeeper,
      'price_per_game': pricePerGame,
      'reflexes': reflexes,
      'positioning': positioning,
      'distribution': distribution,
      'communication': communication,
      'profile_completed': profileCompleted,
      'created_at': createdAt.toIso8601String(),
      'games_played': gamesPlayed,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      name: map['name'],
      gender: map['gender'],
      city: map['city'],
      birthDate: map['birth_date'] != null
          ? DateTime.parse(map['birth_date'])
          : null,
      club: map['club'],
      nationality: map['nationality'],
      country: map['country'],
      isGoalkeeper: map['is_goalkeeper'] ?? false,
      pricePerGame: map['price_per_game']?.toDouble(),
      reflexes: map['reflexes'] != null ? List<int>.from(map['reflexes']) : null,
      positioning: map['positioning'] != null ? List<int>.from(map['positioning']) : null,
      distribution: map['distribution'] != null ? List<int>.from(map['distribution']) : null,
      communication: map['communication'] != null ? List<int>.from(map['communication']) : null,
      profileCompleted: map['profile_completed'] ?? false,
      gamesPlayed: map['games_played'] ?? 0,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));
}
