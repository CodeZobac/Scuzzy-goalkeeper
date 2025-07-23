import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../controllers/notification_controller.dart';
import '../../data/models/notification.dart';
import '../../data/models/notification_category.dart';
import '../../data/repositories/notification_repository.dart';
import '../../services/notification_service.dart';
import '../widgets/contract_notification_card.dart';
import '../widgets/full_lobby_notification_card.dart';
import '../widgets/notification_history_filters.dart';
import '../widgets/notification_pagination_info.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _showSearchBar = false;
  NotificationCategory? _selectedFilter;

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

    _scrollController.addListener(_onScroll);
    
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _listAnimationController.forward();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final controller = context.read<NotificationController>();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && controller.hasMoreNotifications && !controller.isLoadingMore) {
        controller.loadMoreNotifications(user.id);
      }
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
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
          // Load with advanced pagination by default
          controller.loadNotificationsAdvanced(user.id, reset: true);
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
                _buildEnhancedFilters(),
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
                            'Histórico de Notificações',
                            style: AppTheme.headingLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showSearchBar = !_showSearchBar;
                              if (!_showSearchBar) {
                                _searchController.clear();
                                final user = Supabase.instance.client.auth.currentUser;
                                if (user != null) {
                                  controller.clearSearch(user.id);
                                }
                              }
                            });
                          },
                          icon: Icon(
                            _showSearchBar ? Icons.close : Icons.search,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppTheme.primaryText,
                          ),
                          color: AppTheme.secondaryBackground,
                          onSelected: (value) => _handleMenuAction(value, controller),
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'toggle_archived',
                              child: Row(
                                children: [
                                  Icon(
                                    controller.showArchived ? Icons.unarchive : Icons.archive,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    controller.showArchived ? 'Mostrar Ativas' : 'Mostrar Arquivadas',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'cleanup_archived',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_sweep, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Limpar Arquivadas', style: AppTheme.bodyMedium),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete_all',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_forever, size: 18, color: AppTheme.errorColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Eliminar Todas',
                                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStatsRow(controller),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(NotificationController controller) {
    return Row(
      children: [
        _buildStatChip(
          'Total: ${controller.totalNotifications}',
          Icons.notifications,
          AppTheme.accentColor,
        ),
        const SizedBox(width: 8),
        if (controller.unreadCount > 0)
          _buildStatChip(
            'Não lidas: ${controller.unreadCount}',
            Icons.mark_email_unread,
            const Color(0xFFFF9800),
          ),
        const Spacer(),
        if (controller.showArchived)
          _buildStatChip(
            'Arquivadas',
            Icons.archive,
            AppTheme.secondaryText,
          ),
      ],
    );
  }

  Widget _buildStatChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showSearchBar ? 60 : 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
        child: Consumer<NotificationController>(
          builder: (context, controller, child) {
            return TextField(
              controller: _searchController,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Pesquisar notificações...',
                hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText),
                prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.secondaryText),
                        onPressed: () {
                          _searchController.clear();
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user != null) {
                            controller.clearSearch(user.id);
                          }
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.secondaryBackground.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null) {
                      controller.searchNotifications(user.id, value);
                    }
                  }
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedFilters() {
    return Consumer<NotificationController>(
      builder: (context, controller, child) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return const SizedBox.shrink();

        return NotificationHistoryFilters(
          searchQuery: controller.searchQuery,
          selectedCategory: controller.selectedCategory,
          sortBy: controller.sortBy,
          sortAscending: controller.sortAscending,
          dateFrom: controller.dateFrom,
          dateTo: controller.dateTo,
          readStatusFilter: controller.readStatusFilter,
          showArchived: controller.showArchived,
          onSearchChanged: (query) => controller.searchNotifications(user.id, query),
          onCategoryChanged: (category) => controller.filterByCategory(user.id, category),
          onSortChanged: (sortBy, ascending) => controller.setSorting(user.id, sortBy, ascending),
          onDateRangeChanged: (from, to) => controller.setDateRange(user.id, from, to),
          onReadStatusChanged: (status) => controller.setReadStatusFilter(user.id, status),
          onClearFilters: () => controller.clearAllFilters(user.id),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    NotificationCategory? category,
    bool isSelected,
    NotificationController controller,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: AppTheme.bodyMedium.copyWith(
          color: isSelected ? Colors.white : AppTheme.primaryText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          controller.filterByCategory(user.id, selected ? category : null);
        }
      },
      selectedColor: AppTheme.accentColor,
      backgroundColor: AppTheme.secondaryBackground.withOpacity(0.8),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.accentColor : AppTheme.secondaryText.withOpacity(0.3),
      ),
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
                  return _buildEmptyState(controller);
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
    final user = Supabase.instance.client.auth.currentUser;
    
    return Column(
      children: [
        // Pagination info at the top
        NotificationPaginationInfo(
          currentPage: controller.currentPage,
          totalNotifications: controller.totalNotifications,
          pageSize: 20,
          hasMore: controller.hasMoreNotifications,
          isLoading: controller.isLoading,
          isLoadingMore: controller.isLoadingMore,
          onLoadMore: user != null ? () => controller.loadMoreNotifications(user.id) : null,
        ),
        
        // Notifications list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (user != null) {
                await controller.loadNotificationsAdvanced(user.id, reset: true);
              }
            },
            color: AppTheme.accentColor,
            backgroundColor: AppTheme.secondaryBackground,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.spacing),
              itemCount: controller.notifications.length,
              itemBuilder: (context, index) {
                final notification = controller.notifications[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 200 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
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
        ),
        
        // Load more button at the bottom
        NotificationLoadMoreButton(
          hasMore: controller.hasMoreNotifications,
          isLoading: controller.isLoadingMore,
          onPressed: user != null ? () => controller.loadMoreNotifications(user.id) : null,
        ),
      ],
    );
  }

  Widget _buildEnhancedNotificationCard(AppNotification notification, NotificationController controller) {
    Widget card;
    
    // Use new notification card widgets based on type
    if (notification.isContractRequest) {
      card = ContractNotificationCard(
        notification: notification,
        onAccept: () => controller.handleContractAccept(context, notification),
        onDecline: () => controller.handleContractDecline(context, notification),
        onTap: () => _handleNotificationTap(notification, controller),
        isLoading: controller.isActionLoading(notification.id),
      );
    } else if (notification.isFullLobby) {
      card = FullLobbyNotificationCard(
        notification: notification,
        onViewDetails: () => controller.navigateToAnnouncementDetails(context, notification),
        onTap: () => _handleNotificationTap(notification, controller),
        isLoading: controller.isActionLoading(notification.id),
      );
    } else {
      // Fall back to basic card for general notifications
      card = _buildBasicNotificationCard(notification, controller);
    }

    // Add swipe to delete functionality
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: AppTheme.spacing),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmation(notification),
      onDismissed: (direction) {
        controller.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notificação eliminada'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            action: SnackBarAction(
              label: 'Desfazer',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Implement undo functionality
              },
            ),
          ),
        );
      },
      child: card,
    );
  }

  Widget _buildBasicNotificationCard(AppNotification notification, NotificationController controller) {
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
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleNotificationTap(notification, controller),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          Text(
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
                        ],
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notification.displayDate,
                      style: AppTheme.bodyMedium.copyWith(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    const Spacer(),
                    if (notification.isArchived)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryText.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Arquivada',
                          style: AppTheme.bodyMedium.copyWith(
                            fontSize: 10,
                            color: AppTheme.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildEmptyState(NotificationController controller) {
    String title;
    String subtitle;
    IconData icon;
    
    if (controller.searchQuery.isNotEmpty) {
      title = 'Nenhum resultado';
      subtitle = 'Não foram encontradas notificações para "${controller.searchQuery}"';
      icon = Icons.search_off;
    } else if (controller.selectedCategory != null) {
      title = 'Nenhuma notificação';
      subtitle = 'Não há notificações na categoria ${controller.selectedCategory!.title}';
      icon = controller.selectedCategory!.icon;
    } else if (controller.showArchived) {
      title = 'Nenhuma notificação arquivada';
      subtitle = 'As notificações são arquivadas automaticamente após 30 dias';
      icon = Icons.archive;
    } else {
      title = 'Nenhuma notificação';
      subtitle = 'Receberá notificações sobre atividades da sua conta aqui';
      icon = Icons.notifications_none;
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
                controller.loadNotificationsPaginated(user.id, reset: true);
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

  Future<void> _handleNotificationTap(AppNotification notification, NotificationController controller) async {
    // Mark as read when tapped
    if (notification.isUnread) {
      await controller.markAsReadOnView(notification.id);
    }
    
    // Handle navigation
    await controller.handleNotificationNavigation(context, notification);
  }

  Future<bool> _showDeleteConfirmation(AppNotification notification) async {
    return await showDialog<bool>(
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
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Eliminar',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _handleMenuAction(String action, NotificationController controller) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    switch (action) {
      case 'toggle_archived':
        await controller.toggleArchivedView(user.id);
        break;
      case 'cleanup_archived':
        await _showCleanupConfirmation(controller);
        break;
      case 'delete_all':
        await _showDeleteAllConfirmation(controller, user.id);
        break;
    }
  }

  Future<void> _showCleanupConfirmation(NotificationController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: Text(
          'Limpar Notificações Arquivadas',
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Isto irá eliminar permanentemente todas as notificações arquivadas há mais de 90 dias. Esta ação não pode ser desfeita.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Limpar',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await controller.cleanupArchivedNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notificações arquivadas antigas foram eliminadas'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAllConfirmation(NotificationController controller, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: Text(
          'Eliminar Todas as Notificações',
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Tem a certeza que quer eliminar todas as notificações? Esta ação não pode ser desfeita.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Eliminar Todas',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await controller.deleteAllNotifications(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Todas as notificações foram eliminadas'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.sports_soccer;
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'contract_request':
        return Icons.handshake;
      case 'full_lobby':
        return Icons.group;
      default:
        return Icons.notifications;
    }
  }
}