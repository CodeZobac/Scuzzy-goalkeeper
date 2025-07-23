import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../controllers/notification_preferences_controller.dart';
import '../widgets/notification_preference_tile.dart';

/// Screen for managing notification preferences
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Load preferences and start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationPreferencesController>().loadPreferences();
      context.read<NotificationPreferencesController>().watchPreferences();
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
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
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
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando preferências...',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Erro ao carregar preferências',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<NotificationPreferencesController>().loadPreferences();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesContent(NotificationPreferencesController controller) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeaderCard(),
                      const SizedBox(height: AppTheme.spacing),
                      _buildPreferencesCard(controller),
                      const SizedBox(height: AppTheme.spacing),
                      _buildActionsCard(controller),
                      const SizedBox(height: 100), // Bottom padding
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppTheme.primaryText,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Notificações',
          style: AppTheme.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBackground,
                AppTheme.primaryBackground.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.buttonGradient,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gerir Notificações',
              style: AppTheme.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalize que tipos de notificações quer receber',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(NotificationPreferencesController controller) {
    final preferences = controller.preferences;
    if (preferences == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Preferências',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Push notifications master toggle
            NotificationPreferenceTile(
              title: 'Notificações Push',
              subtitle: 'Ativar/desativar todas as notificações push',
              icon: Icons.notifications_active,
              value: preferences.pushNotificationsEnabled,
              onChanged: controller.updatePushNotificationsEnabled,
              isEnabled: true,
              accentColor: AppTheme.accentColor,
            ),
            
            const SizedBox(height: 16),
            
            // Divider
            Container(
              height: 1,
              color: AppTheme.secondaryText.withOpacity(0.1),
            ),
            
            const SizedBox(height: 16),
            
            // Contract notifications
            NotificationPreferenceTile(
              title: 'Contratos de Guarda-Redes',
              subtitle: 'Notificações quando for contratado para jogos',
              icon: Icons.handshake,
              value: preferences.contractNotifications,
              onChanged: controller.updateContractNotifications,
              isEnabled: preferences.pushNotificationsEnabled,
              accentColor: AppTheme.successColor,
            ),
            
            const SizedBox(height: 16),
            
            // Full lobby notifications
            NotificationPreferenceTile(
              title: 'Lobbies Completos',
              subtitle: 'Notificações quando seus anúncios ficarem completos',
              icon: Icons.group,
              value: preferences.fullLobbyNotifications,
              onChanged: controller.updateFullLobbyNotifications,
              isEnabled: preferences.pushNotificationsEnabled,
              accentColor: Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            // General notifications
            NotificationPreferenceTile(
              title: 'Notificações Gerais',
              subtitle: 'Reservas, confirmações e outras notificações',
              icon: Icons.notifications,
              value: preferences.generalNotifications,
              onChanged: controller.updateGeneralNotifications,
              isEnabled: preferences.pushNotificationsEnabled,
              accentColor: AppTheme.accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(NotificationPreferencesController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restore,
                    color: AppTheme.errorColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Ações',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading ? null : () {
                  _showResetConfirmation(controller);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.restore),
                label: const Text(
                  'Restaurar Padrões',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Isto irá restaurar todas as preferências de notificação para os valores padrão.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.secondaryText,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(NotificationPreferencesController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: Text(
          'Restaurar Padrões',
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Tem a certeza que quer restaurar todas as preferências de notificação para os valores padrão?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.resetToDefaults();
            },
            child: Text(
              'Restaurar',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}