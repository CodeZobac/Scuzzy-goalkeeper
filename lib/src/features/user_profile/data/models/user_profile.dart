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

  UserProfile({
    required this.id,
    required this.name,
    this.gender,
    this.city,
    this.birthDate,
    this.club,
    this.nationality,
    this.country,
    this.isGoalkeeper = false,
    this.pricePerGame,
  });

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
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
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
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));
}
