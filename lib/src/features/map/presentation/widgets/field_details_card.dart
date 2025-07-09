import 'package:flutter/material.dart';
import '../../domain/models/map_field.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class FieldDetailsCard extends StatelessWidget {
  final MapField field;
  final VoidCallback? onClose;

  const FieldDetailsCard({
    Key? key,
    required this.field,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacing),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius * 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with photo and close button
          _buildHeader(context),
          
          // Field information
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldName(),
                const SizedBox(height: AppTheme.spacingSmall),
                _buildFieldDetails(),
                if (field.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppTheme.spacing),
                  _buildDescription(),
                ],
                const SizedBox(height: AppTheme.spacing),
                _buildLocationInfo(),
                const SizedBox(height: AppTheme.spacing),
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        // Photo
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.borderRadius * 2),
            ),
            image: field.photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(field.photoUrl!),
                    fit: BoxFit.cover,
                    onError: (error, stackTrace) {
                      // Handle image load error
                    },
                  )
                : null,
            gradient: field.photoUrl == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentColor.withOpacity(0.7),
                      AppTheme.accentColor.withOpacity(0.3),
                    ],
                  )
                : null,
          ),
          child: field.photoUrl == null
              ? const Center(
                  child: Icon(
                    Icons.sports_soccer,
                    size: 60,
                    color: Colors.white70,
                  ),
                )
              : null,
        ),
        
        // Close button
        if (onClose != null)
          Positioned(
            top: AppTheme.spacing,
            right: AppTheme.spacing,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        
        // Status badge
        Positioned(
          top: AppTheme.spacing,
          left: AppTheme.spacing,
          child: _buildStatusBadge(),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    
    switch (field.status.toLowerCase()) {
      case 'approved':
        badgeColor = AppTheme.successColor;
        statusText = 'Aprovado';
        break;
      case 'pending':
        badgeColor = Colors.orange;
        statusText = 'Pendente';
        break;
      case 'rejected':
        badgeColor = AppTheme.errorColor;
        statusText = 'Rejeitado';
        break;
      default:
        badgeColor = AppTheme.secondaryText;
        statusText = field.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: AppTheme.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFieldName() {
    return Text(
      field.name,
      style: AppTheme.headingMedium.copyWith(
        color: AppTheme.primaryText,
      ),
    );
  }

  Widget _buildFieldDetails() {
    return Wrap(
      spacing: AppTheme.spacingSmall,
      runSpacing: AppTheme.spacingSmall,
      children: [
        if (field.surfaceType != null)
          _buildDetailChip(
            icon: Icons.grass,
            label: _getSurfaceTypeLabel(field.surfaceType!),
          ),
        if (field.dimensions != null)
          _buildDetailChip(
            icon: Icons.straighten,
            label: field.dimensions!,
          ),
        _buildDetailChip(
          icon: Icons.calendar_today,
          label: _formatDate(field.createdAt),
        ),
      ],
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrição',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          field.description!,
          style: AppTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppTheme.accentColor,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coordenadas',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${field.latitude.toStringAsFixed(6)}, ${field.longitude.toStringAsFixed(6)}',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openInMaps(context),
            icon: const Icon(Icons.directions),
            label: const Text('Direções'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentColor,
              side: const BorderSide(color: AppTheme.accentColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _shareField(context),
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getSurfaceTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'natural':
        return 'Grama Natural';
      case 'artificial':
        return 'Grama Artificial';
      case 'synthetic':
        return 'Sintético';
      case 'sand':
        return 'Areia';
      case 'indoor':
        return 'Indoor';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _openInMaps(BuildContext context) {
    // TODO: Implement opening in maps app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Abrindo no aplicativo de mapas...'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
      ),
    );
  }

  void _shareField(BuildContext context) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Compartilhando campo...'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
      ),
    );
  }
}
