import 'dart:convert';

class Availability {
  final String id;
  final String goalkeeperId;
  final DateTime day;
  final String startTime; // Format: "HH:mm"
  final String endTime;   // Format: "HH:mm"

  Availability({
    required this.id,
    required this.goalkeeperId,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalkeeper_id': goalkeeperId,
      'day': day.toIso8601String().split('T')[0], // Date only
      'start-time': startTime,
      'end-time': endTime,
    };
  }

  factory Availability.fromMap(Map<String, dynamic> map) {
    return Availability(
      id: map['id'],
      goalkeeperId: map['goalkeeper_id'],
      day: DateTime.parse(map['day']),
      startTime: map['start-time'],
      endTime: map['end-time'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Availability.fromJson(String source) =>
      Availability.fromMap(json.decode(source));

  // Helper methods
  String get displayDay {
    final weekdays = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];
    return '${weekdays[day.weekday - 1]}, ${day.day}/${day.month}/${day.year}';
  }

  String get displayTimeRange {
    return '$startTime - $endTime';
  }

  String get displayFull {
    return '$displayDay: $displayTimeRange';
  }

  // Check if a given DateTime falls within this availability slot
  bool containsDateTime(DateTime dateTime) {
    // Check if the date matches
    if (dateTime.year != day.year ||
        dateTime.month != day.month ||
        dateTime.day != day.day) {
      return false;
    }

    // Parse start and end times
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    final timeInMinutes = dateTime.hour * 60 + dateTime.minute;
    final startInMinutes = startHour * 60 + startMinute;
    final endInMinutes = endHour * 60 + endMinute;

    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  }

  // Get available time slots (assuming 1-hour game slots)
  List<DateTime> getAvailableSlots() {
    final slots = <DateTime>[];
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    final startDateTime = DateTime(
      day.year,
      day.month,
      day.day,
      startHour,
      startMinute,
    );

    final endDateTime = DateTime(
      day.year,
      day.month,
      day.day,
      endHour,
      endMinute,
    );

    DateTime current = startDateTime;
    while (current.isBefore(endDateTime)) {
      slots.add(current);
      current = current.add(const Duration(hours: 1));
    }

    return slots;
  }
}
