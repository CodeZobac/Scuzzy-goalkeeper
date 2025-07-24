import 'package:flutter/material.dart';
import '../../services/contract_management_service.dart';
import '../../services/contract_expiration_handler.dart';

class ContractStatusTracker extends StatelessWidget {
  final GoalkeeperContract contract;
  final bool showTimeLeft;
  final bool showStatusIcon;

  const ContractStatusTracker({
    super.key,
    required this.contract,
    this.showTimeLeft = true,
    this.showStatusIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final expirationStatus = ContractExpirationHandler.getExpirationStatus(contract.expiresAt);
    final timeLeft = ContractExpirationHandler.formatTimeLeft(contract.expiresAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(contract.status, expirationStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(contract.status, expirationStatus).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStatusIcon) ...[
            Icon(
              _getStatusIcon(contract.status, expirationStatus),
              size: 16,
              color: _getStatusColor(contract.status, expirationStatus),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            _getStatusText(contract.status, expirationStatus),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(contract.status, expirationStatus),
            ),
          ),
          if (showTimeLeft && contract.status == ContractStatus.pending && !contract.isExpired) ...[
            const SizedBox(width: 6),
            Text(
              '• $timeLeft',
              style: TextStyle(
                fontSize: 11,
                color: _getStatusColor(contract.status, expirationStatus).withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(ContractStatus status, ExpirationStatus expirationStatus) {
    switch (status) {
      case ContractStatus.pending:
        if (expirationStatus == ExpirationStatus.expired) {
          return Colors.grey;
        } else if (expirationStatus.isUrgent) {
          return Colors.orange;
        }
        return Colors.blue;
      case ContractStatus.accepted:
        return Colors.green;
      case ContractStatus.declined:
        return Colors.red;
      case ContractStatus.expired:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ContractStatus status, ExpirationStatus expirationStatus) {
    switch (status) {
      case ContractStatus.pending:
        if (expirationStatus == ExpirationStatus.expired) {
          return Icons.access_time_filled;
        } else if (expirationStatus.isUrgent) {
          return Icons.warning;
        }
        return Icons.hourglass_empty;
      case ContractStatus.accepted:
        return Icons.check_circle;
      case ContractStatus.declined:
        return Icons.cancel;
      case ContractStatus.expired:
        return Icons.access_time_filled;
    }
  }

  String _getStatusText(ContractStatus status, ExpirationStatus expirationStatus) {
    switch (status) {
      case ContractStatus.pending:
        if (expirationStatus == ExpirationStatus.expired) {
          return 'Expirado';
        } else if (expirationStatus == ExpirationStatus.expiringSoon) {
          return 'Expirando';
        }
        return 'Pendente';
      case ContractStatus.accepted:
        return 'Aceito';
      case ContractStatus.declined:
        return 'Recusado';
      case ContractStatus.expired:
        return 'Expirado';
    }
  }
}

class ContractStatusBadge extends StatelessWidget {
  final ContractStatus status;
  final DateTime? expiresAt;
  final bool compact;

  const ContractStatusBadge({
    super.key,
    required this.status,
    this.expiresAt,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final expirationStatus = expiresAt != null 
        ? ContractExpirationHandler.getExpirationStatus(expiresAt!)
        : ExpirationStatus.active;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status, expirationStatus),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Text(
        _getStatusText(status, expirationStatus),
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getStatusColor(ContractStatus status, ExpirationStatus expirationStatus) {
    switch (status) {
      case ContractStatus.pending:
        if (expirationStatus == ExpirationStatus.expired) {
          return Colors.grey.shade600;
        } else if (expirationStatus.isUrgent) {
          return Colors.orange.shade600;
        }
        return Colors.blue.shade600;
      case ContractStatus.accepted:
        return Colors.green.shade600;
      case ContractStatus.declined:
        return Colors.red.shade600;
      case ContractStatus.expired:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText(ContractStatus status, ExpirationStatus expirationStatus) {
    switch (status) {
      case ContractStatus.pending:
        if (expirationStatus == ExpirationStatus.expired) {
          return 'EXPIRADO';
        } else if (expirationStatus == ExpirationStatus.expiringSoon) {
          return 'EXPIRANDO';
        }
        return 'PENDENTE';
      case ContractStatus.accepted:
        return 'ACEITO';
      case ContractStatus.declined:
        return 'RECUSADO';
      case ContractStatus.expired:
        return 'EXPIRADO';
    }
  }
}

class ContractExpirationIndicator extends StatelessWidget {
  final DateTime expiresAt;
  final bool showIcon;

  const ContractExpirationIndicator({
    super.key,
    required this.expiresAt,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final expirationStatus = ContractExpirationHandler.getExpirationStatus(expiresAt);
    final timeLeft = ContractExpirationHandler.formatTimeLeft(expiresAt);

    if (expirationStatus == ExpirationStatus.active) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getExpirationColor(expirationStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getExpirationColor(expirationStatus).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getExpirationIcon(expirationStatus),
              size: 14,
              color: _getExpirationColor(expirationStatus),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            timeLeft,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getExpirationColor(expirationStatus),
            ),
          ),
        ],
      ),
    );
  }

  Color _getExpirationColor(ExpirationStatus status) {
    switch (status) {
      case ExpirationStatus.active:
        return Colors.green;
      case ExpirationStatus.expiringToday:
        return Colors.orange;
      case ExpirationStatus.expiringSoon:
        return Colors.red;
      case ExpirationStatus.expired:
        return Colors.grey;
    }
  }

  IconData _getExpirationIcon(ExpirationStatus status) {
    switch (status) {
      case ExpirationStatus.active:
        return Icons.check_circle_outline;
      case ExpirationStatus.expiringToday:
        return Icons.schedule;
      case ExpirationStatus.expiringSoon:
        return Icons.warning_outlined;
      case ExpirationStatus.expired:
        return Icons.access_time_filled;
    }
  }
}