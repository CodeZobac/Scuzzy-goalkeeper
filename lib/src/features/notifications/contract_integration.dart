import 'services/contract_management_service.dart';
import 'services/contract_expiration_handler.dart';
import 'services/notification_service.dart';
import 'presentation/controllers/contract_controller.dart';
import 'data/repositories/notification_repository.dart';
import 'data/models/contract_notification_data.dart';

/// Integration class to manage all contract-related services
class ContractIntegration {
  static ContractIntegration? _instance;
  static ContractIntegration get instance => _instance ??= ContractIntegration._();
  
  ContractIntegration._();

  late final ContractManagementService _contractService;
  late final ContractExpirationHandler _expirationHandler;
  late final NotificationRepository _notificationRepository;
  
  bool _initialized = false;

  /// Initialize all contract services
  void initialize() {
    if (_initialized) return;

    _contractService = ContractManagementService();
    _expirationHandler = ContractExpirationHandler();
    _notificationRepository = NotificationRepository();
    
    // Start the expiration handler
    _expirationHandler.start();
    
    _initialized = true;
  }

  /// Get contract management service
  ContractManagementService get contractService {
    if (!_initialized) initialize();
    return _contractService;
  }

  /// Get expiration handler
  ContractExpirationHandler get expirationHandler {
    if (!_initialized) initialize();
    return _expirationHandler;
  }

  /// Get notification repository
  NotificationRepository get notificationRepository {
    if (!_initialized) initialize();
    return _notificationRepository;
  }

  /// Create a new contract controller
  ContractController createController() {
    if (!_initialized) initialize();
    return ContractController();
  }

  /// Dispose all services
  void dispose() {
    if (!_initialized) return;
    
    _expirationHandler.dispose();
    _contractService.dispose();
    _initialized = false;
  }

  /// Perform manual cleanup of expired contracts
  Future<void> performCleanup() async {
    if (!_initialized) initialize();
    await _expirationHandler.performManualCleanup();
  }
}

/// Extension methods for easier access
extension ContractIntegrationExtension on ContractIntegration {
  /// Quick method to create a contract
  Future<GoalkeeperContract> quickCreateContract({
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
    final controller = createController();
    
    final success = await controller.createContractFromAnnouncement(
      goalkeeperUserId: goalkeeperUserId,
      contractorUserId: contractorUserId,
      contractorName: contractorName,
      announcementId: announcementId,
      announcementTitle: announcementTitle,
      gameDateTime: gameDateTime,
      stadium: stadium,
      contractorAvatarUrl: contractorAvatarUrl,
      offeredAmount: offeredAmount,
      additionalNotes: additionalNotes,
      expirationDuration: expirationDuration,
    );

    if (!success) {
      throw Exception(controller.error ?? 'Erro desconhecido ao criar contrato');
    }

    // Get the created contract
    final contracts = await contractService.getAnnouncementContracts(announcementId);
    final contract = contracts.firstWhere(
      (c) => c.goalkeeperUserId == goalkeeperUserId && c.contractorUserId == contractorUserId,
    );

    controller.dispose();
    return contract;
  }

  /// Quick method to handle contract response
  Future<bool> quickHandleContractResponse({
    required String contractId,
    required String notificationId,
    required bool accept,
  }) async {
    final controller = createController();
    
    final success = accept
        ? await controller.acceptContract(contractId: contractId, notificationId: notificationId)
        : await controller.declineContract(contractId: contractId, notificationId: notificationId);

    if (!success) {
      final error = controller.error ?? 'Erro desconhecido ao processar resposta';
      controller.dispose();
      throw Exception(error);
    }

    controller.dispose();
    return success;
  }
}