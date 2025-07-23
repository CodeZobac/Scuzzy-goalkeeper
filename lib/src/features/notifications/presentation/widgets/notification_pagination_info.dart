import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class NotificationPaginationInfo extends StatelessWidget {
  final int currentPage;
  final int totalNotifications;
  final int pageSize;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  const NotificationPaginationInfo({
    super.key,
    required this.currentPage,
    required this.totalNotifications,
    required this.pageSize,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox.shrink();
    }

    final totalPages = (totalNotifications / pageSize).ceil();
    final startItem = ((currentPage - 1) * pageSize) + 1;
    final endItem = (currentPage * pageSize).clamp(0, totalNotifications);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing,
        vertical: AppTheme.spacing / 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.secondaryText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  totalNotifications > 0
                      ? 'Mostrando $startItem-$endItem de $totalNotifications notificações'
                      : 'Nenhuma notificação encontrada',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ),
              if (totalPages > 1) ...[
                Text(
                  'Página $currentPage de $totalPages',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          if (hasMore && !isLoadingMore) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more, size: 16),
                label: const Text('Carregar mais'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
          if (isLoadingMore) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Carregando mais...',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class NotificationLoadMoreButton extends StatelessWidget {
  final bool hasMore;
  final bool isLoading;
  final VoidCallback? onPressed;

  const NotificationLoadMoreButton({
    super.key,
    required this.hasMore,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacing),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: AppTheme.secondaryText.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Todas as notificações foram carregadas',
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 12,
                color: AppTheme.secondaryText.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      child: Center(
        child: isLoading
            ? Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Carregando mais notificações...',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              )
            : ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.expand_more),
                label: const Text('Carregar mais'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                ),
              ),
      ),
    );
  }
}

class NotificationPaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final Function(int) onPageChanged;

  const NotificationPaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: currentPage > 1 && !isLoading
                ? () => onPageChanged(currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: currentPage > 1
                  ? AppTheme.accentColor.withOpacity(0.1)
                  : AppTheme.secondaryText.withOpacity(0.1),
              foregroundColor: currentPage > 1
                  ? AppTheme.accentColor
                  : AppTheme.secondaryText,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Page numbers
          ...List.generate(
            totalPages.clamp(0, 5),
            (index) {
              int pageNumber;
              if (totalPages <= 5) {
                pageNumber = index + 1;
              } else {
                // Show pages around current page
                final start = (currentPage - 2).clamp(1, totalPages - 4);
                pageNumber = start + index;
              }
              
              final isCurrentPage = pageNumber == currentPage;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: !isLoading && !isCurrentPage
                      ? () => onPageChanged(pageNumber)
                      : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrentPage
                          ? AppTheme.accentColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrentPage
                            ? AppTheme.accentColor
                            : AppTheme.secondaryText.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        pageNumber.toString(),
                        style: AppTheme.bodyMedium.copyWith(
                          color: isCurrentPage
                              ? Colors.white
                              : AppTheme.primaryText,
                          fontWeight: isCurrentPage
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(width: 16),
          
          // Next button
          IconButton(
            onPressed: currentPage < totalPages && !isLoading
                ? () => onPageChanged(currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: currentPage < totalPages
                  ? AppTheme.accentColor.withOpacity(0.1)
                  : AppTheme.secondaryText.withOpacity(0.1),
              foregroundColor: currentPage < totalPages
                  ? AppTheme.accentColor
                  : AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}