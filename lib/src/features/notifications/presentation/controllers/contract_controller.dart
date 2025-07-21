import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/contract_management_service.dart';
import '../../data/models/contract_notification_data.dart';
import '../../data/models/notification.dart';

class ContractController extends ChangeNotifier {
  final ContractManagementService _contractService = ContractManagementService();
  
  // Loading states
  bool _isCreatingContract = false;
  bool _isAcceptingContract = false;
  bool _isDecliningContract = false;
  
  // Error handling
  String? _error;
  
  // Contract data
  List<GoalkeeperContract> _goalkeeperContracts = [];
  List<GoalkeeperContract> _contractorContracts = [];
  
  // Streams
  StreamSubscription? _goalkeeperContractsSubscription;
  StreamSubscription? _contractorContractsSubscription;

  // Getters
  bool get isCreatingContract => _isCreatingContract;
  bool get isAcceptingContract => _isAcceptingContract;
  bool get isDecliningContract => _isDecliningContract;
  bool get isLoading => _isCreatingContract || _isAcceptingContract || _isDecliningContract;
  String? get error => _error;
  List<GoalkeeperContract> get goalkeeperContracts => _goalkeeperContracts;
  List<GoalkeeperContract> get contractorContracts => _contractorContracts;

  /// Create a new goalkeeper contract
  Future<bool> createContract({
    required String goalkeeperUserId,
    required String contractorUserId,
    required String announcementId,
    required ContractNotificationData notificationData,
    Duration? expirationDuration,
  }) async {
    _setCreatingContract(true);
    _clearError();

    try {
      await _contractService.createContract(
        goalkeeperUserId: goalkeeperUserId,
        contractorUserId: contractorUserId,
        announcementId: announcementId,
        notificationData: notificationData,
        expirationDuration: expirationDuration,
      );
      
      return true;
    } catch (e) {
      _setError('Erro ao criar contrato: $e');
      return false;
    } finally {
      _setCreatingContract(false);
    }
  }

  /// Accept a contract
  Future<bool> acceptContract({
    required String contractId,
    required String notificationId,
  }) async {
    _setAcceptingContract(true);
    _clearError();

    try {
      await _contractService.acceptContract(
        contractId: contractId,
        notificationId: notificationId,
      );
      
      return true;
    } catch (e) {
      _setError('Erro ao aceitar contrato: $e');
      return false;
    } finally {
      _setAcceptingContract(false);
    }
  }

  /// Decline a contract
  Future<bool> declineContract({
    required String contractId,
    required String notificationId,
  }) async {
    _setDecliningContract(true);
    _clearError();

    try {
      await _contractService.declineContract(
        contractId: contractId,
        notificationId: notificationId,
      );
      
      return true;
    } catch (e) {
      _setError('Erro ao recusar contrato: $e');
      return false;
    } finally {
      _setDecliningContract(false);
    }
  }

  /// Load goalkeeper contracts
  Future<void> loadGoalkeeperContracts(String goalkeeperUserId) async {
    try {
      _goalkeeperContracts = await _contractService.getGoalkeeperContracts(goalkeeperUserId);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar contratos do goleiro: $e');
    }
  }

  /// Load contractor contracts
  Future<void> loadContractorContracts(String contractorUserId) async {
    try {
      _contractorContracts = await _contractService.getContractorContracts(contractorUserId);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar contratos criados: $e');
    }
  }

  /// Watch goalkeeper contracts in real-time
  void watchGoalkeeperContracts(String goalkeeperUserId) {
    _goalkeeperContractsSubscription?.cancel();
    _goalkeeperContractsSubscription = _contractService
        .watchGoalkeeperContracts(goalkeeperUserId)
        .listen(
          (contracts) {
            _goalkeeperContracts = contracts;
            notifyListeners();
          },
          onError: (error) {
            _setError('Erro ao monitorar contratos: $error');
          },
        );
  }

  /// Check if goalkeeper has pending contract for announcement
  Future<bool> hasGoalkeeperPendingContract({
    required String goalkeeperUserId,
    required String announcementId,
  }) async {
    try {
      return await _contractService.hasGoalkeeperPendingContract(
        goalkeeperUserId: goalkeeperUserId,
        announcementId: announcementId,
      );
    } catch (e) {
      return false;
    }
  }

  /// Get contract status
  Future<ContractStatus?> getContractStatus(String contractId) async {
    try {
      return await _contractService.getContractStatus(contractId);
    } catch (e) {
      return null;
    }
  }

  /// Handle contract action from notification
  Future<bool> handleContractAction({
    required AppNotification notification,
    required bool accept,
  }) async {
    final contractId = notification.contractId;
    if (contractId == null) {
      _setError('ID do contrato não encontrado');
      return false;
    }

    if (accept) {
      return await acceptContract(
        contractId: contractId,
        notificationId: notification.id,
      );
    } else {
      return await declineContract(
        contractId: contractId,
        notificationId: notification.id,
      );
    }
  }

  /// Clean up expired contracts manually
  Future<void> cleanupExpiredContracts() async {
    try {
      await _contractService.cleanupExpiredContracts();
    } catch (e) {
      _setError('Erro na limpeza de contratos expirados: $e');
    }
  }

  /// Get contract details
  Future<GoalkeeperContract?> getContract(String contractId) async {
    try {
      return await _contractService.getContract(contractId);
    } catch (e) {
      _setError('Erro ao buscar contrato: $e');
      return null;
    }
  }

  /// Get contracts for announcement
  Future<List<GoalkeeperContract>> getAnnouncementContracts(String announcementId) async {
    try {
      return await _contractService.getAnnouncementContracts(announcementId);
    } catch (e) {
      _setError('Erro ao buscar contratos do anúncio: $e');
      return [];
    }
  }

  /// Helper method to create contract from announcement data
  Future<bool> createContractFromAnnouncement({
    required String goalkeeperUserId,
    required String contractorUserId,
    required String contractorName,
    required String announcementId,
    required String announcementTitle,
    required DateTime gameDateTime,
    required String stadium,
    String? contractorAvatarUrl,
    double? offeredAmount,
    String? additionalNotes,
    Duration? expirationDuration,
  }) async {
    final notificationData = ContractNotificationData(
      contractId: '', // Will be set by the service
      contractorId: contractorUserId,
      contractorName: contractorName,
      contractorAvatarUrl: contractorAvatarUrl,
      announcementId: announcementId,
      announcementTitle: announcementTitle,
      gameDateTime: gameDateTime,
      stadium: stadium,
      offeredAmount: offeredAmount,
      additionalNotes: additionalNotes,
    );

    return await createContract(
      goalkeeperUserId: goalkeeperUserId,
      contractorUserId: contractorUserId,
      announcementId: announcementId,
      notificationData: notificationData,
      expirationDuration: expirationDuration,
    );
  }

  // Private helper methods
  void _setCreatingContract(bool value) {
    _isCreatingContract = value;
    notifyListeners();
  }

  void _setAcceptingContract(bool value) {
    _isAcceptingContract = value;
    notifyListeners();
  }

  void _setDecliningContract(bool value) {
    _isDecliningContract = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Clear error manually
  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _goalkeeperContractsSubscription?.cancel();
    _contractorContractsSubscription?.cancel();
    _contractService.dispose();
    super.dispose();
  }
}