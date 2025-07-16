import 'package:flutter/material.dart';

class Announcement {
  final int id;
  final String? createdBy;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay time;
  final double? price;
  final String? stadium;
  final DateTime createdAt;

  Announcement({
    required this.id,
    this.createdBy,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    this.price,
    this.stadium,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      createdBy: json['created_by'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: TimeOfDay(
        hour: int.parse(json['time'].split(':')[0]),
        minute: int.parse(json['time'].split(':')[1]),
      ),
      price: json['price']?.toDouble(),
      stadium: json['stadium'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'price': price,
      'stadium': stadium,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
