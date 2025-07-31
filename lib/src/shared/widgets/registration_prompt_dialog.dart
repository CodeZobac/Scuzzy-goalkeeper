import 'package:flutter/material.dart';
import '../../features/auth/data/models/registration_prompt_config.dart';
import '../../features/auth/presentation/theme/app_theme.dart';

/// A beautiful dialog that prompts guest users to create an account
/// 
/// This dialog is shown when guest users attempt to perform actions
/// that require authentication. It provides a friendly, non-pushy
/// way to encourage account creation.
class RegistrationPromptDialog extends StatelessWidget {
  /// Configuration for the registration prompt
  final RegistrationPromptConfig config;
  
  /// Optional custom styling
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final Color? primaryButtonColor;
  final Color? secondaryButtonColor;
  
  const RegistrationPromptDialog({
    super.key,
    required this.config,
    this.titleStyle,
    this.messageStyle,
    this.primaryButtonColor,
    this.secondaryButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppTheme.authCardBackground,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  /// Build the dialog header with icon and title
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        gradient: AppTheme.authPrimaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.borderRadiusLarge),
          topRight: Radius.circular(AppTheme.borderRadiusLarge),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForContext(),
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacing),
          Text(
            config.title,
            style: titleStyle ?? AppTheme.authHeadingSmall.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build the dialog content with message
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        children: [
          Text(
            config.message,
            style: messageStyle ?? AppTheme.authBodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing),
          _buildBenefitsList(),
        ],
      ),
    );
  }

  /// Build a list of benefits for creating an account
  Widget _buildBenefitsList() {
    final benefits = _getBenefitsForContext();
    
    if (benefits.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Com a sua conta pode:',
          style: AppTheme.authBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        ...benefits.map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppTheme.authPrimaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  benefit,
                  style: AppTheme.authBodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// Build the dialog action buttons
  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        children: [
          // Primary button (Create Account)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryButtonColor ?? AppTheme.authPrimaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                elevation: 0,
              ),
              child: Text(
                config.primaryButtonText,
                style: AppTheme.authButtonText,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          // Secondary button (Not Now)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: secondaryButtonColor ?? AppTheme.authTextSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                config.secondaryButtonText,
                style: AppTheme.authBodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get appropriate icon based on context
  IconData _getIconForContext() {
    switch (config.context) {
      case 'join_match':
        return Icons.sports_soccer;
      case 'hire_goalkeeper':
        return Icons.sports_handball;
      case 'profile_access':
        return Icons.person;
      case 'create_announcement':
        return Icons.campaign;
      default:
        return Icons.account_circle;
    }
  }

  /// Get benefits list based on context
  List<String> _getBenefitsForContext() {
    switch (config.context) {
      case 'join_match':
        return [
          'Participar de partidas',
          'Conectar-se com outros jogadores',
          'Receber notificações de jogos',
          'Gerir as suas participações',
        ];
      case 'hire_goalkeeper':
        return [
          'Contratar goleiros profissionais',
          'Gerir as suas reservas',
          'Avaliar e ser avaliado',
          'Histórico de contratações',
        ];
      case 'profile_access':
        return [
          'Personalizar o seu perfil',
          'Aceder a recursos exclusivos',
          'Histórico de atividades',
          'Configurações personalizadas',
        ];
      case 'create_announcement':
        return [
          'Criar anúncios de partidas',
          'Organizar eventos esportivos',
          'Gerir participantes',
          'Receber notificações',
        ];
      default:
        return [
          'Aceder a todos os recursos',
          'Personalizar experiência',
          'Conectar-se com a comunidade',
          'Receber notificações',
        ];
    }
  }
}

/// Utility methods for showing registration prompts
class RegistrationPromptDialogUtils {
  /// Show a registration prompt dialog
  static Future<bool?> show(
    BuildContext context,
    RegistrationPromptConfig config, {
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    Color? primaryButtonColor,
    Color? secondaryButtonColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => RegistrationPromptDialog(
        config: config,
        titleStyle: titleStyle,
        messageStyle: messageStyle,
        primaryButtonColor: primaryButtonColor,
        secondaryButtonColor: secondaryButtonColor,
      ),
    );
  }

  /// Show a join match registration prompt
  static Future<bool?> showJoinMatchPrompt(BuildContext context) {
    return show(context, RegistrationPromptConfig.joinMatch);
  }

  /// Show a hire goalkeeper registration prompt
  static Future<bool?> showHireGoalkeeperPrompt(BuildContext context) {
    return show(context, RegistrationPromptConfig.hireGoalkeeper);
  }

  /// Show a profile access registration prompt
  static Future<bool?> showProfileAccessPrompt(BuildContext context) {
    return show(context, RegistrationPromptConfig.profileAccess);
  }

  /// Show a create announcement registration prompt
  static Future<bool?> showCreateAnnouncementPrompt(BuildContext context) {
    return show(context, RegistrationPromptConfig.createAnnouncement);
  }
}