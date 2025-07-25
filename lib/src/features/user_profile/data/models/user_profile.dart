import 'dart:convert';

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
  });

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
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));
}
