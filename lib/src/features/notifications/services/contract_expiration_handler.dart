import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'contract_management_service.dart';

/// Handles contract expiration logic and automatic cleanup
class ContractExpirationHandler {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ContractManagementService _contractService = ContractManagementService();
  
  Timer? _expirationTimer;
  Timer? _cleanupTimer;
  
  static const Duration _checkInterval = Duration(minutes: 5);
  static const Duration _cleanupInterval = Duration(hours: 1);
  static const Duration _defaultExpirationDuration = Duration(hours: 24);

  /// Start the expiration handler
  void start() {
    _startExpirationTimer();
    _startCleanupTimer();
  }

  /// Stop the expiration handler
  void stop() {
    _expirationTimer?.cancel();
    _cleanupTimer?.cancel();
  }

  /// Start timer to check for expiring contracts
  void _startExpirationTimer() {
    _expirationTimer = Timer.periodic(_checkInterval, (_) {
      _checkExpiringContracts();
    });
  }

  /// Start timer for cleanup operations
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// Check for contracts that are about to expire or have expired
  Future<void> _checkExpiringContracts() async {
    try {
      final now = DateTime.now();
      final soonToExpire = now.add(const Duration(hours: 1)); // 1 hour warning

      // Get contracts expiring soon
      final expiringContracts = await _supabase
          .from('goalkeeper_contracts')
          .select('''
            *,
            goalkeeper:goalkeeper_user_id(id, name),
            contractor:contractor_user_id(id, name),
            announcement:announcement_id(title)
          ''')
          .eq('status', ContractStatus.pending.value)
          .gte('expires_at', now.toIso8601String())
          .lte('expires_at', soonToExpire.toIso8601String());

      // Send expiration warnings
      for (final contractData in expiringContracts) {
        await _sendExpirationWarning(contractData);
      }

      // Get expired contracts
      final expiredContracts = await _supabase
          .from('goalkeeper_contracts')
          .select('id')
          .eq('status', ContractStatus.pending.value)
          .lt('expires_at', now.toIso8601String());

      if (expiredContracts.isNotEmpty) {
        await _handleExpiredContracts(expiredContracts);
      }
    } catch (e) {
      print('Erro ao verificar contratos expirando: $e');
    }
  }

  /// Send expiration warning notification
  Future<void> _sendExpirationWarning(Map<String, dynamic> contractData) async {
    try {
      final contractId = contractData['id'];
      final goalkeeperUserId = contractData['goalkeeper_user_id'];
      final contractorName = contractData['contractor']['name'];
      final announcementTitle = contractData['announcement']['title'];
      final expiresAt = DateTime.parse(contractData['expires_at']);
      
      final timeLeft = expiresAt.difference(DateTime.now());
      final hoursLeft = timeLeft.inHours;
      final minutesLeft = timeLeft.inMinutes % 60;

      String timeLeftText;
      if (hoursLeft > 0) {
        timeLeftText = '${hoursLeft}h ${minutesLeft}m';
      } else {
        timeLeftText = '${minutesLeft}m';
      }

      // Check if warning was already sent (to avoid spam)
      final existingWarning = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', goalkeeperUserId)
          .eq('type', 'contract_expiring')
          .eq('data->contract_id', contractId);

      if (existingWarning.isNotEmpty) return;

      // Create expiration warning notification
      await _supabase.from('notifications').insert({
        'user_id': goalkeeperUserId,
        'title': 'Contrato Expirando',
        'body': 'Seu contrato com $contractorName para "$announcementTitle" expira em $timeLeftText',
        'type': 'contract_expiring',
        'data': {
          'contract_id': contractId,
          'contractor_name': contractorName,
          'announcement_title': announcementTitle,
          'expires_at': contractData['expires_at'],
          'time_left': timeLeftText,
        },
        'category': 'contracts',
        'requires_action': true,
        'sent_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erro ao enviar aviso de expiração: $e');
    }
  }

  /// Handle expired contracts
  Future<void> _handleExpiredContracts(List<Map<String, dynamic>> expiredContracts) async {
    try {
      final now = DateTime.now();
      final expiredContractIds = expiredContracts
          .map<String>((contract) => contract['id'] as String)
          .toList();

      // Update contract status to expired
      await _supabase
          .from('goalkeeper_contracts')
          .update({
            'status': ContractStatus.expired.value,
            'responded_at': now.toIso8601String(),
          })
          .inFilter('id', expiredContractIds);

      // Mark related notifications as expired
      await _supabase
          .from('notifications')
          .update({
            'read_at': now.toIso8601String(),
            'action_taken_at': now.toIso8601String(),
          })
          .eq('type', 'contract_request')
          .inFilter('data->contract_id', expiredContractIds);

      // Send expiration notifications to contractors
      for (final contractId in expiredContractIds) {
        await _sendContractExpiredNotification(contractId);
      }

      print('Contratos expirados processados: ${expiredContractIds.length}');
    } catch (e) {
      print('Erro ao processar contratos expirados: $e');
    }
  }

  /// Send contract expired notification to contractor
  Future<void> _sendContractExpiredNotification(String contractId) async {
    try {
      final contractData = await _supabase
          .from('goalkeeper_contracts')
          .select('''
            *,
            goalkeeper:goalkeeper_user_id(name),
            announcement:announcement_id(title)
          ''')
          .eq('id', contractId)
          .single();

      final contractorUserId = contractData['contractor_user_id'];
      final goalkeeperName = contractData['goalkeeper']['name'];
      final announcementTitle = contractData['announcement']['title'];

      await _supabase.from('notifications').insert({
        'user_id': contractorUserId,
        'title': 'Contrato Expirado',
        'body': 'Seu contrato com $goalkeeperName para "$announcementTitle" expirou sem resposta',
        'type': 'contract_expired',
        'data': {
          'contract_id': contractId,
          'goalkeeper_name': goalkeeperName,
          'announcement_title': announcementTitle,
          'expired_at': DateTime.now().toIso8601String(),
        },
        'category': 'contracts',
        'requires_action': false,
        'sent_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erro ao enviar notificação de contrato expirado: $e');
    }
  }

  /// Perform general cleanup operations
  Future<void> _performCleanup() async {
    try {
      await _cleanupOldNotifications();
      await _cleanupOldContracts();
    } catch (e) {
      print('Erro na limpeza geral: $e');
    }
  }

  /// Clean up old notifications (older than 30 days)
  Future<void> _cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      await _supabase
          .from('notifications')
          .delete()
          .lt('created_at', thirtyDaysAgo.toIso8601String())
          .inFilter('type', ['contract_expiring', 'contract_expired']);

      print('Notificações antigas de contrato limpas');
    } catch (e) {
      print('Erro ao limpar notificações antigas: $e');
    }
  }

  /// Clean up old contracts (older than 90 days)
  Future<void> _cleanupOldContracts() async {
    try {
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      
      final oldContracts = await _supabase
          .from('goalkeeper_contracts')
          .select('id')
          .lt('created_at', ninetyDaysAgo.toIso8601String())
          .inFilter('status', [
            ContractStatus.expired.value,
            ContractStatus.declined.value,
          ]);

      if (oldContracts.isNotEmpty) {
        final oldContractIds = oldContracts
            .map<String>((contract) => contract['id'] as String)
            .toList();

        // Delete old contracts
        await _supabase
            .from('goalkeeper_contracts')
            .delete()
            .inFilter('id', oldContractIds);

        print('Contratos antigos limpos: ${oldContractIds.length}');
      }
    } catch (e) {
      print('Erro ao limpar contratos antigos: $e');
    }
  }

  /// Get time until contract expires
  static Duration getTimeUntilExpiration(DateTime expiresAt) {
    return expiresAt.difference(DateTime.now());
  }

  /// Check if contract is about to expire (within 1 hour)
  static bool isContractAboutToExpire(DateTime expiresAt) {
    final timeLeft = getTimeUntilExpiration(expiresAt);
    return timeLeft.inHours <= 1 && timeLeft.inMinutes > 0;
  }

  /// Format time left for display
  static String formatTimeLeft(DateTime expiresAt) {
    final timeLeft = getTimeUntilExpiration(expiresAt);
    
    if (timeLeft.isNegative) {
      return 'Expirado';
    }
    
    if (timeLeft.inDays > 0) {
      return '${timeLeft.inDays}d ${timeLeft.inHours % 24}h';
    } else if (timeLeft.inHours > 0) {
      return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m';
    } else if (timeLeft.inMinutes > 0) {
      return '${timeLeft.inMinutes}m';
    } else {
      return 'Expirando...';
    }
  }

  /// Get expiration status for UI
  static ExpirationStatus getExpirationStatus(DateTime expiresAt) {
    final timeLeft = getTimeUntilExpiration(expiresAt);
    
    if (timeLeft.isNegative) {
      return ExpirationStatus.expired;
    } else if (timeLeft.inHours <= 1) {
      return ExpirationStatus.expiringSoon;
    } else if (timeLeft.inHours <= 6) {
      return ExpirationStatus.expiringToday;
    } else {
      return ExpirationStatus.active;
    }
  }

  /// Manual cleanup method
  Future<void> performManualCleanup() async {
    await _performCleanup();
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}

/// Expiration status enum for UI display
enum ExpirationStatus {
  active,
  expiringToday,
  expiringSoon,
  expired,
}

extension ExpirationStatusExtension on ExpirationStatus {
  String get displayText {
    switch (this) {
      case ExpirationStatus.active:
        return 'Ativo';
      case ExpirationStatus.expiringToday:
        return 'Expira hoje';
      case ExpirationStatus.expiringSoon:
        return 'Expirando em breve';
      case ExpirationStatus.expired:
        return 'Expirado';
    }
  }

  bool get isUrgent {
    return this == ExpirationStatus.expiringSoon || this == ExpirationStatus.expired;
  }
}