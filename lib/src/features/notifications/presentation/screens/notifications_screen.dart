import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../controllers/notification_controller.dart';
import '../controllers/notification_badge_controller.dart';
import '../../data/models/notification.dart';
import '../../data/models/notification_category.dart';
import '../../data/repositories/notification_repository.dart';
import '../../services/notification_service.dart';
import '../widgets/contract_notification_card.dart';
import '../widgets/full_lobby_notification_card.dart';
import 'notification_history_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late TabController _tabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  


  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(
      length: NotificationCategory.values.length,
      vsync: this,
    );
    
    _headerAnimationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _listAnimationController = AnimationController(
      duration: AppTheme.longAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeOutCubic,
    ));
    

    
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _listAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final controller = NotificationController(
          NotificationRepository(),
          context.read<NotificationService>(),
        );
        
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final badgeController = context.read<NotificationBadgeController>();
          controller.initialize(user.id, badgeController: badgeController);
        }
        
        return controller;
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Consumer<NotificationController>(
              builder: (context, controller, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Notificações',
                            style: AppTheme.headingLarge,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationHistoryScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.history,
                                size: 16,
                                color: AppTheme.accentColor,
                              ),
                              label: Text(
                                'Histórico',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (controller.hasUnreadNotifications) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  final user = Supabase.instance.client.auth.currentUser;
                                  if (user != null) {
                                    controller.markAllAsRead(user.id);
                                  }
                                },
                                child: Text(
                                  'Marcar todas como lidas',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (controller.hasUnreadNotifications) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${controller.unreadCount} notificação${controller.unreadCount != 1 ? 's' : ''} não lida${controller.unreadCount != 1 ? 's' : ''}',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildConnectionStatus(controller),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Consumer<NotificationController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                    ),
                  );
                }

                if (controller.error != null) {
                  return _buildErrorState(controller);
                }

                return Column(
                  children: [
                    _buildCategoryTabs(controller),
                    Expanded(
                      child: _buildTabContent(controller),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTabs(NotificationController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.buttonGradient,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.secondaryText,
        labelStyle: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: AppTheme.bodyMedium.copyWith(
          fontSize: 12,
        ),
        tabs: NotificationCategory.values.map((category) {
          final categoryNotifications = _getNotificationsByCategory(controller.notifications, category);
          final unreadCount = categoryNotifications.where((n) => n.isUnread).length;
          
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    category.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(NotificationController controller) {
    return TabBarView(
      controller: _tabController,
      children: NotificationCategory.values.map((category) {
        final categoryNotifications = _getNotificationsByCategory(controller.notifications, category);
        
        if (categoryNotifications.isEmpty) {
          return _buildCategoryEmptyState(category);
        }
        
        return _buildCategoryNotificationsList(categoryNotifications, controller, category);
      }).toList(),
    );
  }

  Widget _buildCategoryNotificationsList(List<AppNotification> notifications, NotificationController controller, NotificationCategory category) {
    final unreadNotifications = notifications.where((n) => n.isUnread).toList();
    final hasUnreadInCategory = unreadNotifications.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await controller.loadNotificationsAdvanced(user.id, reset: true);
          // Auto-archive old notifications on refresh
          await controller.archiveOldNotifications(user.id);
        }
      },
      color: AppTheme.accentColor,
      backgroundColor: AppTheme.secondaryBackground,
      child: Column(
        children: [
          // Category header with mark all as read button
          if (hasUnreadInCategory)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing,
                vertical: AppTheme.spacing / 2,
              ),
              child: Row(
                children: [
                  Text(
                    '${unreadNotifications.length} não lida${unreadNotifications.length != 1 ? 's' : ''}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user != null) {
                        controller.markAllAsReadByCategory(user.id, category);
                      }
                    },
                    child: Text(
                      'Marcar todas como lidas',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Notifications list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 200 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildEnhancedNotificationCard(notification, controller),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryEmptyState(NotificationCategory category) {
    String title;
    String subtitle;
    IconData icon;
    
    switch (category) {
      case NotificationCategory.contracts:
        title = 'Nenhum contrato';
        subtitle = 'Receberá notificações quando alguém quiser contratá-lo para um jogo';
        icon = Icons.handshake;
        break;
      case NotificationCategory.fullLobbies:
        title = 'Nenhum lobby completo';
        subtitle = 'Receberá notificações quando seus anúncios atingirem a capacidade máxima';
        icon = Icons.group;
        break;
      case NotificationCategory.general:
        title = 'Nenhuma notificação';
        subtitle = 'Receberá notificações gerais sobre atividades da sua conta';
        icon = Icons.notifications_none;
        break;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.secondaryText.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacing),
            Text(
              title,
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<AppNotification> _getNotificationsByCategory(List<AppNotification> notifications, NotificationCategory category) {
    return notifications.where((notification) => notification.category == category).toList();
  }

  Widget _buildEnhancedNotificationCard(AppNotification notification, NotificationController controller) {
    // Use new notification card widgets based on type
    if (notification.isContractRequest) {
      return ContractNotificationCard(
        notification: notification,
        onAccept: () => controller.handleContractAccept(context, notification),
        onDecline: () => controller.handleContractDecline(context, notification),
        onTap: () => _handleNotificationTap(notification, controller),
        isLoading: controller.isActionLoading(notification.id),
      );
    } else if (notification.isFullLobby) {
      return FullLobbyNotificationCard(
        notification: notification,
        onViewDetails: () => controller.navigateToAnnouncementDetails(context, notification),
        onTap: () => _handleNotificationTap(notification, controller),
        isLoading: controller.isActionLoading(notification.id),
      );
    } else {
      // Fall back to original card for general notifications
      return _buildNotificationCard(notification, controller);
    }
  }

  /// Handle notification tap and mark as read
  Future<void> _handleNotificationTap(AppNotification notification, NotificationController controller) async {
    // Mark as read when tapped
    if (notification.isUnread) {
      await controller.markAsReadOnView(notification.id);
    }
    
    // Handle navigation
    await controller.handleNotificationNavigation(context, notification);
  }





  Widget _buildNotificationCard(AppNotification notification, NotificationController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: notification.isUnread
            ? Border.all(
                color: const Color(0xFFFF9800).withOpacity(0.3),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(notification.isUnread ? 0.15 : 0.08),
            blurRadius: notification.isUnread ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          onTap: () => _handleNotificationTap(notification, controller),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: notification.isUnread
                        ? AppTheme.buttonGradient
                        : LinearGradient(
                            colors: [
                              AppTheme.secondaryText.withOpacity(0.3),
                              AppTheme.secondaryText.withOpacity(0.2),
                            ],
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: notification.isUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: notification.isUnread
                                    ? AppTheme.primaryText
                                    : AppTheme.secondaryText,
                              ),
                            ),
                          ),
                          if (notification.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppTheme.bodyMedium.copyWith(
                          color: notification.isUnread
                              ? AppTheme.primaryText
                              : AppTheme.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.displayTime,
                            style: AppTheme.bodyMedium.copyWith(
                              fontSize: 12,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                          const Spacer(),
                          if (notification.isBookingRequest)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Pedido de Agendamento',
                                style: AppTheme.bodyMedium.copyWith(
                                  fontSize: 10,
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppTheme.secondaryText,
                    size: 20,
                  ),
                  color: AppTheme.secondaryBackground,
                  onSelected: (value) {
                    switch (value) {
                      case 'mark_read':
                        if (notification.isUnread) {
                          controller.markAsRead(notification.id);
                        }
                        break;
                      case 'delete':
                        _showDeleteConfirmation(notification, controller);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (notification.isUnread)
                      PopupMenuItem<String>(
                        value: 'mark_read',
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_read, size: 18),
                            const SizedBox(width: 8),
                            Text('Marcar como lida', style: AppTheme.bodyMedium),
                          ],
                        ),
                      ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                          const SizedBox(width: 8),
                          Text(
                            'Eliminar',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildErrorState(NotificationController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.errorColor.withOpacity(0.7),
          ),
          const SizedBox(height: AppTheme.spacing),
          Text(
            'Erro ao carregar notificações',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.error ?? 'Erro desconhecido',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          ElevatedButton(
            onPressed: () {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                controller.loadNotificationsAdvanced(user.id, reset: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
            child: Text(
              'Tentar Novamente',
              style: AppTheme.buttonText,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.sports_soccer;
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'booking_cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }



  Widget _buildConnectionStatus(NotificationController controller) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: controller.isRealtimeConnected 
                ? Colors.green 
                : Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          controller.isRealtimeConnected 
              ? 'Atualizações em tempo real ativas'
              : 'Reconectando...',
          style: AppTheme.bodyMedium.copyWith(
            fontSize: 12,
            color: controller.isRealtimeConnected 
                ? Colors.green 
                : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (!controller.isRealtimeConnected)
          TextButton(
            onPressed: () => controller.reconnectRealtime(),
            child: Text(
              'Reconectar',
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 12,
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  void _showDeleteConfirmation(AppNotification notification, NotificationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: Text(
          'Eliminar Notificação',
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Tem a certeza que quer eliminar esta notificação?',
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
              controller.deleteNotification(notification.id);
            },
            child: Text(
              'Eliminar',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
