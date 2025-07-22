import 'dart:convert';

class Booking {
  final String id;
  final String playerId;
  final String goalkeeperId;
  final String fieldId;
  final DateTime gameDatetime;
  final double price;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.playerId,
    required this.goalkeeperId,
    required this.fieldId,
    required this.gameDatetime,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'player_id': playerId,
      'goalkeeper_id': goalkeeperId,
      'field_id': fieldId,
      'game_datetime': gameDatetime.toIso8601String(),
      'price': price,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      playerId: map['player_id'],
      goalkeeperId: map['goalkeeper_id'],
      fieldId: map['field_id'],
      gameDatetime: DateTime.parse(map['game_datetime']),
      price: (map['price'] as num).toDouble(),
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Booking.fromJson(String source) =>
      Booking.fromMap(json.decode(source));

  // Helper methods
  bool get isCompleted {
    return status == 'completed' && gameDatetime.isBefore(DateTime.now());
  }

  String get displayDateTime {
    final date = gameDatetime.toLocal();
    return '${date.day}/${date.month}/${date.year} às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Create booking for submission
  Map<String, dynamic> toCreateMap() {
    return {
      'player_id': playerId,
      'goalkeeper_id': goalkeeperId,
      'field_id': fieldId,
      'game_datetime': gameDatetime.toIso8601String(),
      'price': price,
      'status': status,
    };
  }
}
