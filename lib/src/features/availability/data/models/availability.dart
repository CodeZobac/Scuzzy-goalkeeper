import 'package:flutter/material.dart';

class Availability {
  final String? id;
  final String goalkeeperId;
  final DateTime day;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  Availability({
    this.id,
    required this.goalkeeperId,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      id: json['id'],
      goalkeeperId: json['goalkeeper_id'],
      day: DateTime.parse(json['day']),
      startTime: TimeOfDay(
        hour: int.parse(json['start-time'].split(':')[0]),
        minute: int.parse(json['start-time'].split(':')[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(json['end-time'].split(':')[0]),
        minute: int.parse(json['end-time'].split(':')[1]),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalkeeper_id': goalkeeperId,
      'day': day.toIso8601String().split('T')[0], // Only date part
      'start-time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
      'end-time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'goalkeeper_id': goalkeeperId,
      'day': day.toIso8601String().split('T')[0],
      'start-time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
      'end-time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
    };
  }

  String get formattedDate {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    const weekdays = [
      'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    ];
    
    return '${weekdays[day.weekday - 1]}, ${day.day} de ${months[day.month - 1]}';
  }

  String get formattedTimeRange {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool get isValid {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes > startMinutes;
  }

  @override
  String toString() {
    return 'Availability(id: $id, goalkeeperId: $goalkeeperId, day: $day, startTime: $startTime, endTime: $endTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Availability &&
        other.id == id &&
        other.goalkeeperId == goalkeeperId &&
        other.day == day &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        goalkeeperId.hashCode ^
        day.hashCode ^
        startTime.hashCode ^
        endTime.hashCode;
  }
}
