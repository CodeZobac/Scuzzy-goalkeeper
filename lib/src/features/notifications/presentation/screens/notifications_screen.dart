import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../controllers/notification_controller.dart';
import '../../data/models/notification.dart';
import '../../data/repositories/notification_repository.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
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
          controller.initialize(user.id);
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
                        if (controller.hasUnreadNotifications)
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

                if (controller.notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildNotificationsList(controller);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList(NotificationController controller) {
    return RefreshIndicator(
      onRefresh: () async {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await controller.refreshNotifications(user.id);
        }
      },
      color: AppTheme.accentColor,
      backgroundColor: AppTheme.secondaryBackground,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
        itemCount: controller.notifications.length,
        itemBuilder: (context, index) {
          final notification = controller.notifications[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildNotificationCard(notification, controller),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, NotificationController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            notification.isUnread
                ? AppTheme.accentColor.withOpacity(0.1)
                : AppTheme.secondaryBackground.withOpacity(0.8),
            notification.isUnread
                ? AppTheme.accentColor.withOpacity(0.05)
                : AppTheme.secondaryBackground.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: notification.isUnread
            ? Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          onTap: () {
            if (notification.isUnread) {
              controller.markAsRead(notification.id);
            }
            _handleNotificationTap(notification);
          },
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
                          Icon(
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
                  icon: Icon(
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: AppTheme.secondaryText.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacing),
          Text(
            'Nenhuma notificação',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Receberá notificações quando alguém agendar um jogo consigo',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
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
                controller.refreshNotifications(user.id);
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

  void _handleNotificationTap(AppNotification notification) {
    if (notification.isBookingRequest && notification.data != null) {
      // Navigate to booking details or booking management
      // This would typically be handled by the main navigation system
      debugPrint('Navigate to booking: ${notification.data}');
    }
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
