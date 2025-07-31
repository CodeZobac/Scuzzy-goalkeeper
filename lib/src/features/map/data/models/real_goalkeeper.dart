class RealGoalkeeper {
  final String id;
  final String name;
  final String? city;
  final String? country;
  final String? nationality;
  final String? club;
  final DateTime? birthDate;
  final double? pricePerGame;
  final List<int>? reflexes;
  final List<int>? positioning;
  final List<int>? distribution;
  final List<int>? communication;
  final bool profileCompleted;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  RealGoalkeeper({
    required this.id,
    required this.name,
    this.city,
    this.country,
    this.nationality,
    this.club,
    this.birthDate,
    this.pricePerGame,
    this.reflexes,
    this.positioning,
    this.distribution,
    this.communication,
    this.profileCompleted = false,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory RealGoalkeeper.fromJson(Map<String, dynamic> json) {
    return RealGoalkeeper(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String?,
      country: json['country'] as String?,
      nationality: json['nationality'] as String?,
      club: json['club'] as String?,
      birthDate: json['birth_date'] != null 
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      pricePerGame: json['price_per_game'] != null
          ? double.tryParse(json['price_per_game'].toString())
          : null,
      reflexes: json['reflexes'] != null
          ? List<int>.from(json['reflexes'] as List)
          : null,
      positioning: json['positioning'] != null
          ? List<int>.from(json['positioning'] as List)
          : null,
      distribution: json['distribution'] != null
          ? List<int>.from(json['distribution'] as List)
          : null,
      communication: json['communication'] != null
          ? List<int>.from(json['communication'] as List)
          : null,
      profileCompleted: json['profile_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'country': country,
      'nationality': nationality,
      'club': club,
      'birth_date': birthDate?.toIso8601String(),
      'price_per_game': pricePerGame,
      'reflexes': reflexes,
      'positioning': positioning,
      'distribution': distribution,
      'communication': communication,
      'profile_completed': profileCompleted,
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Computed properties for display
  String get displayLocation => city ?? 'Portugal';
  
  String get displayPrice {
    if (pricePerGame != null) {
      return '€${pricePerGame!.toStringAsFixed(0)}/jogo';
    }
    return 'Preço a combinar';
  }

  String get displayClub => club ?? 'Sem clube';
  
  String get displayNationality => nationality ?? 'Portugal';

  int? get age {
    final birth = birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month || 
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  String get displayAge {
    final ageValue = age;
    if (ageValue != null) {
      return '$ageValue anos';
    }
    return 'Idade não informada';
  }

  // Calculate overall skill rating based on goalkeeper attributes
  double get overallRating {
    final skills = [reflexes, positioning, distribution, communication]
        .where((skill) => skill != null && skill.isNotEmpty)
        .map((skill) {
          final s = skill!;
          return s.reduce((a, b) => a + b) / s.length;
        })
        .toList();
    
    if (skills.isEmpty) return 3.0; // Default rating
    
    return skills.reduce((a, b) => a + b) / skills.length;
  }

  String get displayOverallRating {
    return '${overallRating.toStringAsFixed(1)} ⭐';
  }

  // Experience level based on profile completion and skills
  int get experienceLevel {
    if (!profileCompleted) return 1;
    
    final rating = overallRating;
    if (rating >= 4.5) return 5; // Expert
    if (rating >= 4.0) return 4; // Advanced
    if (rating >= 3.5) return 3; // Intermediate
    if (rating >= 3.0) return 2; // Beginner+
    return 1; // Beginner
  }

  String get displayExperienceLevel {
    switch (experienceLevel) {
      case 5:
        return 'Especialista';
      case 4:
        return 'Avançado';
      case 3:
        return 'Intermédio';
      case 2:
        return 'Iniciante+';
      default:
        return 'Iniciante';
    }
  }

  // Status based on profile completion and recent activity
  String get status {
    if (!profileCompleted) return 'offline';
    
    // In a real app, you'd check last activity timestamp
    // For now, assume active if profile is completed
    return 'available';
  }

  bool get isVerified => profileCompleted && pricePerGame != null;
}
