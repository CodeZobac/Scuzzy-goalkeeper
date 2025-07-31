import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/contract_notification_data.dart';
import '../data/repositories/notification_repository.dart';

enum ContractStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  expired('expired');

  const ContractStatus(this.value);
  final String value;

  static ContractStatus fromString(String value) {
    return ContractStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ContractStatus.pending,
    );
  }
}

class GoalkeeperContract {
  final String id;
  final String announcementId;
  final String goalkeeperUserId;
  final String contractorUserId;
  final double? offeredAmount;
  final ContractStatus status;
  final String? additionalNotes;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;

  GoalkeeperContract({
    required this.id,
    required this.announcementId,
    required this.goalkeeperUserId,
    required this.contractorUserId,
    this.offeredAmount,
    required this.status,
    this.additionalNotes,
    required this.createdAt,
    this.respondedAt,
    required this.expiresAt,
  });

  factory GoalkeeperContract.fromMap(Map<String, dynamic> map) {
    return GoalkeeperContract(
      id: map['id'],
      announcementId: map['announcement_id'].toString(),
      goalkeeperUserId: map['goalkeeper_user_id'],
      contractorUserId: map['contractor_user_id'],
      offeredAmount: map['offered_amount']?.toDouble(),
      status: ContractStatus.fromString(map['status']),
      additionalNotes: map['additional_notes'],
      createdAt: DateTime.parse(map['created_at']),
      respondedAt: map['responded_at'] != null 
          ? DateTime.parse(map['responded_at']) 
          : null,
      expiresAt: DateTime.parse(map['expires_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'announcement_id': announcementId,
      'goalkeeper_user_id': goalkeeperUserId,
      'contractor_user_id': contractorUserId,
      'offered_amount': offeredAmount,
      'status': status.value,
      'additional_notes': additionalNotes,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == ContractStatus.pending && !isExpired;
  bool get isAccepted => status == ContractStatus.accepted;
  bool get isDeclined => status == ContractStatus.declined;
}

class ContractManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationRepository _notificationRepository = NotificationRepository();
  Timer? _cleanupTimer;

  ContractManagementService() {
    _startCleanupTimer();
  }

  /// Create a new goalkeeper contract request
  Future<GoalkeeperContract> createContract({
    required String goalkeeperUserId,
    required String contractorUserId,
    required String announcementId,
    required ContractNotificationData notificationData,
    Duration? expirationDuration,
  }) async {
    try {
      final expiresAt = DateTime.now().add(expirationDuration ?? const Duration(hours: 24));
      
      // Check if there's already a pending contract for this announcement and goalkeeper
      final existingContracts = await _supabase
          .from('goalkeeper_contracts')
          .select('*')
          .eq('announcement_id', announcementId)
          .eq('goalkeeper_user_id', goalkeeperUserId)
          .eq('status', 'pending');

      if (existingContracts.isNotEmpty) {
        throw Exception('Já existe um contrato pendente para este guarda-redes neste anúncio');
      }

      // Create the contract record
      final contractResponse = await _supabase
          .from('goalkeeper_contracts')
          .insert({
            'announcement_id': announcementId,
            'goalkeeper_user_id': goalkeeperUserId,
            'contractor_user_id': contractorUserId,
            'offered_amount': notificationData.offeredAmount,
            'additional_notes': notificationData.additionalNotes,
            'status': ContractStatus.pending.value,
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();

      final contract = GoalkeeperContract.fromMap(contractResponse);

      // Create the notification with the contract ID
      final updatedNotificationData = notificationData.copyWith(
        contractId: contract.id,
      );

      await _notificationRepository.createContractNotification(
        goalkeeperUserId: goalkeeperUserId,
        contractorUserId: contractorUserId,
        announcementId: announcementId,
        data: updatedNotificationData,
      );

      return contract;
    } catch (e) {
      throw Exception('Erro ao criar contrato: $e');
    }
  }

  /// Accept a contract
  Future<void> acceptContract({
    required String contractId,
    required String notificationId,
  }) async {
    try {
      final contract = await getContract(contractId);
      
      if (contract.isExpired) {
        throw Exception('Este contrato expirou');
      }

      if (contract.status != ContractStatus.pending) {
        throw Exception('Este contrato já foi respondido');
      }

      await _notificationRepository.handleContractResponse(
        notificationId: notificationId,
        contractId: contractId,
        accepted: true,
      );

      // Cancel any other pending contracts for the same announcement
      await _cancelOtherPendingContracts(
        announcementId: contract.announcementId,
        excludeContractId: contractId,
      );
    } catch (e) {
      throw Exception('Erro ao aceitar contrato: $e');
    }
  }

  /// Decline a contract
  Future<void> declineContract({
    required String contractId,
    required String notificationId,
  }) async {
    try {
      final contract = await getContract(contractId);
      
      if (contract.isExpired) {
        throw Exception('Este contrato expirou');
      }

      if (contract.status != ContractStatus.pending) {
        throw Exception('Este contrato já foi respondido');
      }

      await _notificationRepository.handleContractResponse(
        notificationId: notificationId,
        contractId: contractId,
        accepted: false,
      );
    } catch (e) {
      throw Exception('Erro ao recusar contrato: $e');
    }
  }

  /// Get a specific contract
  Future<GoalkeeperContract> getContract(String contractId) async {
    try {
      final response = await _supabase
          .from('goalkeeper_contracts')
          .select('*')
          .eq('id', contractId)
          .single();

      return GoalkeeperContract.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao pesquisar contrato: $e');
    }
  }

  /// Get contracts for a goalkeeper
  Future<List<GoalkeeperContract>> getGoalkeeperContracts(String goalkeeperUserId) async {
    try {
      final response = await _supabase
          .from('goalkeeper_contracts')
          .select('*')
          .eq('goalkeeper_user_id', goalkeeperUserId)
          .order('created_at', ascending: false);

      return response
          .map<GoalkeeperContract>((data) => GoalkeeperContract.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao pesquisar contratos do guarda-redes: $e');
    }
  }

  /// Get contracts created by a user
  Future<List<GoalkeeperContract>> getContractorContracts(String contractorUserId) async {
    try {
      final response = await _supabase
          .from('goalkeeper_contracts')
          .select('*')
          .eq('contractor_user_id', contractorUserId)
          .order('created_at', ascending: false);

      return response
          .map<GoalkeeperContract>((data) => GoalkeeperContract.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao pesquisar contratos criados: $e');
    }
  }

  /// Get contracts for a specific announcement
  Future<List<GoalkeeperContract>> getAnnouncementContracts(String announcementId) async {
    try {
      final response = await _supabase
          .from('goalkeeper_contracts')
          .select('*')
          .eq('announcement_id', announcementId)
          .order('created_at', ascending: false);

      return response
          .map<GoalkeeperContract>((data) => GoalkeeperContract.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao pesquisar contratos do anúncio: $e');
    }
  }

  /// Cancel other pending contracts for the same announcement (when one is accepted)
  Future<void> _cancelOtherPendingContracts({
    required String announcementId,
    required String excludeContractId,
  }) async {
    try {
      await _supabase
          .from('goalkeeper_contracts')
          .update({
            'status': ContractStatus.declined.value,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('announcement_id', announcementId)
          .eq('status', ContractStatus.pending.value)
          .neq('id', excludeContractId);
    } catch (e) {
      // Log error but don't throw to avoid breaking the main flow
      print('Erro ao cancelar outros contratos pendentes: $e');
    }
  }

  /// Start the cleanup timer for expired contracts
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupExpiredContracts();
    });
  }

  /// Clean up expired contracts and notifications
  Future<void> _cleanupExpiredContracts() async {
    try {
      final now = DateTime.now();
      
      // Get expired contracts that are still pending
      final expiredContracts = await _supabase
          .from('goalkeeper_contracts')
          .select('id')
          .eq('status', ContractStatus.pending.value)
          .lt('expires_at', now.toIso8601String());

      if (expiredContracts.isEmpty) return;

      final expiredContractIds = expiredContracts
          .map<String>((contract) => contract['id'] as String)
          .toList();

      // Update expired contracts status
      await _supabase
          .from('goalkeeper_contracts')
          .update({
            'status': ContractStatus.expired.value,
            'responded_at': now.toIso8601String(),
          })
          .inFilter('id', expiredContractIds);

      // Mark related notifications as expired and read
      await _supabase
          .from('notifications')
          .update({
            'read_at': now.toIso8601String(),
            'action_taken_at': now.toIso8601String(),
          })
          .eq('type', 'contract_request')
          .inFilter('data->contract_id', expiredContractIds);

      print('Limpeza de contratos expirados concluída: ${expiredContractIds.length} contratos');
    } catch (e) {
      print('Erro na limpeza de contratos expirados: $e');
    }
  }

  /// Manual cleanup method that can be called externally
  Future<void> cleanupExpiredContracts() async {
    await _cleanupExpiredContracts();
  }

  /// Check if a goalkeeper has any pending contracts for an announcement
  Future<bool> hasGoalkeeperPendingContract({
    required String goalkeeperUserId,
    required String announcementId,
  }) async {
    try {
      final response = await _supabase
          .from('goalkeeper_contracts')
          .select('id')
          .eq('goalkeeper_user_id', goalkeeperUserId)
          .eq('announcement_id', announcementId)
          .eq('status', ContractStatus.pending.value)
          .gt('expires_at', DateTime.now().toIso8601String());

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get contract status for tracking
  Future<ContractStatus?> getContractStatus(String contractId) async {
    try {
      final response = await _supabase
          .from('goalkeeper_contracts')
          .select('status')
          .eq('id', contractId)
          .single();

      return ContractStatus.fromString(response['status']);
    } catch (e) {
      return null;
    }
  }

  /// Watch contract status changes for real-time updates
  Stream<GoalkeeperContract> watchContract(String contractId) {
    return _supabase
        .from('goalkeeper_contracts')
        .stream(primaryKey: ['id'])
        .eq('id', contractId)
        .map((List<Map<String, dynamic>> data) {
          return GoalkeeperContract.fromMap(data.first);
        });
  }

  /// Watch contracts for a goalkeeper
  Stream<List<GoalkeeperContract>> watchGoalkeeperContracts(String goalkeeperUserId) {
    return _supabase
        .from('goalkeeper_contracts')
        .stream(primaryKey: ['id'])
        .eq('goalkeeper_user_id', goalkeeperUserId)
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> data) {
          return data.map((item) => GoalkeeperContract.fromMap(item)).toList();
        });
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
  }
}