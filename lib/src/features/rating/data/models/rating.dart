import 'dart:convert';

class Rating {
  final String id;
  final String bookingId;
  final String playerId;
  final String goalkeeperId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.bookingId,
    required this.playerId,
    required this.goalkeeperId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'player_id': playerId,
      'goalkeeper_id': goalkeeperId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      id: map['id'],
      bookingId: map['booking_id'],
      playerId: map['player_id'],
      goalkeeperId: map['goalkeeper_id'],
      rating: map['rating'] as int,
      comment: map['comment'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Rating.fromJson(String source) =>
      Rating.fromMap(json.decode(source));

  // Helper methods
  String get displayRating {
    return '$rating/5 estrelas';
  }

  String get displayStars {
    return '★' * rating + '☆' * (5 - rating);
  }

  String get displayDate {
    final date = createdAt.toLocal();
    return '${date.day}/${date.month}/${date.year}';
  }

  bool get hasComment => comment != null && comment!.isNotEmpty;

  // Create rating for submission
  Map<String, dynamic> toCreateMap() {
    return {
      'booking_id': bookingId,
      'player_id': playerId,
      'goalkeeper_id': goalkeeperId,
      'rating': rating,
      'comment': comment,
    };
  }
}
