import 'dart:convert';

class ContractNotificationData {
  final String contractId;
  final String contractorId;
  final String contractorName;
  final String? contractorAvatarUrl;
  final String announcementId;
  final String announcementTitle;
  final DateTime gameDateTime;
  final String stadium;
  final double? offeredAmount;
  final String? additionalNotes;

  ContractNotificationData({
    required this.contractId,
    required this.contractorId,
    required this.contractorName,
    this.contractorAvatarUrl,
    required this.announcementId,
    required this.announcementTitle,
    required this.gameDateTime,
    required this.stadium,
    this.offeredAmount,
    this.additionalNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'contract_id': contractId,
      'contractor_id': contractorId,
      'contractor_name': contractorName,
      'contractor_avatar_url': contractorAvatarUrl,
      'announcement_id': announcementId,
      'announcement_title': announcementTitle,
      'game_date_time': gameDateTime.toIso8601String(),
      'stadium': stadium,
      'offered_amount': offeredAmount,
      'additional_notes': additionalNotes,
    };
  }

  factory ContractNotificationData.fromMap(Map<String, dynamic> map) {
    return ContractNotificationData(
      contractId: map['contract_id'] ?? '',
      contractorId: map['contractor_id'] ?? '',
      contractorName: map['contractor_name'] ?? '',
      contractorAvatarUrl: map['contractor_avatar_url'],
      announcementId: map['announcement_id'] ?? '',
      announcementTitle: map['announcement_title'] ?? '',
      gameDateTime: DateTime.parse(map['game_date_time']),
      stadium: map['stadium'] ?? '',
      offeredAmount: map['offered_amount']?.toDouble(),
      additionalNotes: map['additional_notes'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ContractNotificationData.fromJson(String source) =>
      ContractNotificationData.fromMap(json.decode(source));

  ContractNotificationData copyWith({
    String? contractId,
    String? contractorId,
    String? contractorName,
    String? contractorAvatarUrl,
    String? announcementId,
    String? announcementTitle,
    DateTime? gameDateTime,
    String? stadium,
    double? offeredAmount,
    String? additionalNotes,
  }) {
    return ContractNotificationData(
      contractId: contractId ?? this.contractId,
      contractorId: contractorId ?? this.contractorId,
      contractorName: contractorName ?? this.contractorName,
      contractorAvatarUrl: contractorAvatarUrl ?? this.contractorAvatarUrl,
      announcementId: announcementId ?? this.announcementId,
      announcementTitle: announcementTitle ?? this.announcementTitle,
      gameDateTime: gameDateTime ?? this.gameDateTime,
      stadium: stadium ?? this.stadium,
      offeredAmount: offeredAmount ?? this.offeredAmount,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ContractNotificationData &&
        other.contractId == contractId &&
        other.contractorId == contractorId &&
        other.contractorName == contractorName &&
        other.contractorAvatarUrl == contractorAvatarUrl &&
        other.announcementId == announcementId &&
        other.announcementTitle == announcementTitle &&
        other.gameDateTime == gameDateTime &&
        other.stadium == stadium &&
        other.offeredAmount == offeredAmount &&
        other.additionalNotes == additionalNotes;
  }

  @override
  int get hashCode {
    return contractId.hashCode ^
        contractorId.hashCode ^
        contractorName.hashCode ^
        contractorAvatarUrl.hashCode ^
        announcementId.hashCode ^
        announcementTitle.hashCode ^
        gameDateTime.hashCode ^
        stadium.hashCode ^
        offeredAmount.hashCode ^
        additionalNotes.hashCode;
  }
}