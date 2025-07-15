import 'dart:convert';

class Booking {
  final String id;
  final String playerId;
  final String goalkeeperId;
  final String? fieldId;
  final DateTime gameDateTime;
  final double price;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.playerId,
    required this.goalkeeperId,
    this.fieldId,
    required this.gameDateTime,
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
      'game_datetime': gameDateTime.toIso8601String(),
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
      gameDateTime: DateTime.parse(map['game_datetime']),
      price: (map['price'] as num).toDouble(),
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Booking.fromJson(String source) =>
      Booking.fromMap(json.decode(source));

  // Helper methods
  String get displayPrice {
    return '€${price.toStringAsFixed(2)}';
  }

  String get displayStatus {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'cancelled':
        return 'Cancelado';
      case 'completed':
        return 'Concluído';
      default:
        return status;
    }
  }

  String get displayDateTime {
    final date = gameDateTime.toLocal();
    return '${date.day}/${date.month}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
}
