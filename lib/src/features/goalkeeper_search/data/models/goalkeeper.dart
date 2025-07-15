import 'dart:convert';

class Goalkeeper {
  final String id;
  final String name;
  final String? city;
  final double? pricePerGame;
  final String? gender;
  final String? club;
  final String? nationality;
  final String? country;
  final DateTime? birthDate;

  Goalkeeper({
    required this.id,
    required this.name,
    this.city,
    this.pricePerGame,
    this.gender,
    this.club,
    this.nationality,
    this.country,
    this.birthDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'price_per_game': pricePerGame,
      'gender': gender,
      'club': club,
      'nationality': nationality,
      'country': country,
      'birth_date': birthDate?.toIso8601String(),
    };
  }

  factory Goalkeeper.fromMap(Map<String, dynamic> map) {
    return Goalkeeper(
      id: map['id'],
      name: map['name'],
      city: map['city'],
      pricePerGame: map['price_per_game']?.toDouble(),
      gender: map['gender'],
      club: map['club'],
      nationality: map['nationality'],
      country: map['country'],
      birthDate: map['birth_date'] != null
          ? DateTime.parse(map['birth_date'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Goalkeeper.fromJson(String source) =>
      Goalkeeper.fromMap(json.decode(source));

  // Helper methods
  String get displayPrice {
    if (pricePerGame == null) return 'Preço não definido';
    return '€${pricePerGame!.toStringAsFixed(2)}/jogo';
  }

  String get displayLocation {
    return city ?? 'Localização não definida';
  }

  String get displayClub {
    return club ?? 'Clube não definido';
  }

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    final age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      return age - 1;
    }
    return age;
  }

  String get displayAge {
    final currentAge = age;
    return currentAge != null ? '$currentAge anos' : 'Idade não definida';
  }
}
