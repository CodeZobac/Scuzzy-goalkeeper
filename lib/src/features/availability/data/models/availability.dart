class Availability {
  final String id;
  final String goalkeeperId;
  final DateTime day;
  final String startTime;
  final String endTime;
  final DateTime? createdAt;

  Availability({
    required this.id,
    required this.goalkeeperId,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalkeeper_id': goalkeeperId,
      'day': day.toIso8601String().split('T')[0], // Only date part
      'start_time': startTime,
      'end_time': endTime,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory Availability.fromMap(Map<String, dynamic> map) {
    return Availability(
      id: map['id'],
      goalkeeperId: map['goalkeeper_id'],
      day: DateTime.parse(map['day']),
      startTime: map['start_time'],
      endTime: map['end_time'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Availability copyWith({
    String? id,
    String? goalkeeperId,
    DateTime? day,
    String? startTime,
    String? endTime,
    DateTime? createdAt,
  }) {
    return Availability(
      id: id ?? this.id,
      goalkeeperId: goalkeeperId ?? this.goalkeeperId,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Availability(id: $id, goalkeeperId: $goalkeeperId, day: $day, startTime: $startTime, endTime: $endTime, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Availability &&
        other.id == id &&
        other.goalkeeperId == goalkeeperId &&
        other.day == day &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        goalkeeperId.hashCode ^
        day.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        createdAt.hashCode;
  }

  /// Helper method to format day for display
  String get formattedDay {
    final weekdays = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado'
    ];
    final months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    
    return '${weekdays[day.weekday % 7]}, ${day.day} ${months[day.month - 1]}';
  }

  /// Helper method to format time range for display
  String get formattedTimeRange {
    return '$startTime - $endTime';
  }

  /// Helper method to check if this availability is in the past
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final availabilityDate = DateTime(day.year, day.month, day.day);
    
    return availabilityDate.isBefore(today);
  }

  /// Helper method to check if this availability is today
  bool get isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }
}
