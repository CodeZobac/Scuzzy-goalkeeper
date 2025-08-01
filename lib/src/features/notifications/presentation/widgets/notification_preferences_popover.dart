import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../controllers/notification_preferences_controller.dart';
import 'notification_preference_tile.dart';

/// Popover widget for managing notification preferences
class NotificationPreferencesPopover extends StatefulWidget {
  const NotificationPreferencesPopover({super.key});

  @override
  State<NotificationPreferencesPopover> createState() => _NotificationPreferencesPopoverState();
}

class _NotificationPreferencesPopoverState extends State<NotificationPreferencesPopover>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Load preferences and start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationPreferencesController>().loadPreferences();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
                decoration: BoxDecoration(
                  color: AppTheme.authCardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Consumer<NotificationPreferencesController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading && controller.preferences == null) {
                      return _buildLoadingState();
                    }

                    if (controller.error != null && controller.preferences == null) {
                      return _buildErrorState(controller.error!);
                    }

                    return _buildPreferencesContent(controller);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.authPrimaryGradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 24),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.authPrimaryGreen),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando preferências...',
            style: AppTheme.authBodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.authError.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.error_outline,
              size: 30,
              color: AppTheme.authError,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar',
            style: AppTheme.authHeadingSmall.copyWith(
              color: AppTheme.authError,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTheme.authBodyMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<NotificationPreferencesController>().loadPreferences();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.authPrimaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesContent(NotificationPreferencesController controller) {
    final preferences = controller.preferences;
    if (preferences == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.authPrimaryGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Gerir Notificações',
                      style: AppTheme.authHeadingMedium.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Personalize que tipos de notificações quer receber',
                style: AppTheme.authBodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        
        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Push notifications master toggle
                _buildPreferenceTile(
                  title: 'Notificações Push',
                  subtitle: 'Ativar/desativar todas as notificações push',
                  icon: Icons.notifications_active,
                  value: preferences.pushNotificationsEnabled,
                  onChanged: controller.updatePushNotificationsEnabled,
                  isEnabled: true,
                  accentColor: AppTheme.authPrimaryGreen,
                ),
                
                const SizedBox(height: 16),
                
                // Divider
                Container(
                  height: 1,
                  color: AppTheme.authInputBorder,
                ),
                
                const SizedBox(height: 16),
                
                // Contract notifications
                _buildPreferenceTile(
                  title: 'Contratos de Guarda-Redes',
                  subtitle: 'Notificações quando for contratado para jogos',
                  icon: Icons.handshake,
                  value: preferences.contractNotifications,
                  onChanged: controller.updateContractNotifications,
                  isEnabled: preferences.pushNotificationsEnabled,
                  accentColor: AppTheme.authSuccess,
                ),
                
                const SizedBox(height: 16),
                
                // Full lobby notifications
                _buildPreferenceTile(
                  title: 'Lobbies Completos',
                  subtitle: 'Notificações quando os seus anúncios ficarem completos',
                  icon: Icons.group,
                  value: preferences.fullLobbyNotifications,
                  onChanged: controller.updateFullLobbyNotifications,
                  isEnabled: preferences.pushNotificationsEnabled,
                  accentColor: Colors.blue,
                ),
                
                const SizedBox(height: 16),
                
                // General notifications
                _buildPreferenceTile(
                  title: 'Notificações Gerais',
                  subtitle: 'Reservas, confirmações e outras notificações',
                  icon: Icons.notifications,
                  value: preferences.generalNotifications,
                  onChanged: controller.updateGeneralNotifications,
                  isEnabled: preferences.pushNotificationsEnabled,
                  accentColor: AppTheme.authPrimaryGreen,
                ),
                
                const SizedBox(height: 24),
                
                // Reset button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: controller.isLoading ? null : () {
                      _showResetConfirmation(controller);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppTheme.authInputBorder),
                      ),
                    ),
                    icon: Icon(
                      Icons.restore,
                      color: AppTheme.authTextSecondary,
                      size: 18,
                    ),
                    label: Text(
                      'Restaurar Padrões',
                      style: AppTheme.authBodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required bool isEnabled,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.authBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.authInputBorder,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.1),
                accentColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTheme.authBodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isEnabled ? AppTheme.authTextPrimary : AppTheme.authTextSecondary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.authBodyMedium.copyWith(
            fontSize: 12,
            color: isEnabled ? AppTheme.authTextSecondary : AppTheme.authTextSecondary.withOpacity(0.6),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: isEnabled ? onChanged : null,
          activeColor: accentColor,
          activeTrackColor: accentColor.withOpacity(0.3),
          inactiveThumbColor: AppTheme.authTextSecondary.withOpacity(0.5),
          inactiveTrackColor: AppTheme.authInputBorder,
        ),
      ),
    );
  }

  void _showResetConfirmation(NotificationPreferencesController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.authCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.authError.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restore,
                color: AppTheme.authError,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Restaurar Padrões',
              style: AppTheme.authBodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.authTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Tem a certeza que quer restaurar todas as preferências de notificação para os valores padrão?',
          style: AppTheme.authBodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.authInputBorder),
              ),
            ),
            child: Text(
              'Cancelar',
              style: AppTheme.authBodyMedium.copyWith(
                color: AppTheme.authTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.resetToDefaults();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: AppTheme.authError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Restaurar',
              style: AppTheme.authBodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}