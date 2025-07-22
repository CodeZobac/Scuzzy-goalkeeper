import 'package:flutter/material.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../data/models/notification_category.dart';

class NotificationHistoryFilters extends StatefulWidget {
  final String searchQuery;
  final NotificationCategory? selectedCategory;
  final String sortBy;
  final bool sortAscending;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool? readStatusFilter;
  final bool showArchived;
  final Function(String) onSearchChanged;
  final Function(NotificationCategory?) onCategoryChanged;
  final Function(String, bool) onSortChanged;
  final Function(DateTime?, DateTime?) onDateRangeChanged;
  final Function(bool?) onReadStatusChanged;
  final Function() onClearFilters;

  const NotificationHistoryFilters({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.sortBy,
    required this.sortAscending,
    required this.dateFrom,
    required this.dateTo,
    required this.readStatusFilter,
    required this.showArchived,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onDateRangeChanged,
    required this.onReadStatusChanged,
    required this.onClearFilters,
  });

  @override
  State<NotificationHistoryFilters> createState() => _NotificationHistoryFiltersState();
}

class _NotificationHistoryFiltersState extends State<NotificationHistoryFilters> {
  final TextEditingController _searchController = TextEditingController();
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.borderRadius),
        ),
      ),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: AppTheme.spacing),
          _buildQuickFilters(),
          if (_showAdvancedFilters) ...[
            const SizedBox(height: AppTheme.spacing),
            _buildAdvancedFilters(),
          ],
          const SizedBox(height: AppTheme.spacing / 2),
          _buildFilterActions(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: AppTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Pesquisar por título, conteúdo, nome...',
        hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText),
        prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.secondaryText),
                onPressed: () {
                  _searchController.clear();
                  widget.onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
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
            widget.onSearchChanged(value);
          }
        });
      },
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryFilter(),
          const SizedBox(width: 8),
          _buildReadStatusFilter(),
          const SizedBox(width: 8),
          _buildSortFilter(),
          const SizedBox(width: 8),
          _buildAdvancedToggle(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return PopupMenuButton<NotificationCategory?>(
      child: _buildFilterChip(
        label: widget.selectedCategory?.title ?? 'Todas',
        icon: widget.selectedCategory?.icon ?? Icons.filter_list,
        isActive: widget.selectedCategory != null,
      ),
      onSelected: widget.onCategoryChanged,
      itemBuilder: (context) => [
        PopupMenuItem<NotificationCategory?>(
          value: null,
          child: Row(
            children: [
              const Icon(Icons.all_inclusive, size: 18),
              const SizedBox(width: 8),
              Text('Todas', style: AppTheme.bodyMedium),
            ],
          ),
        ),
        ...NotificationCategory.values.map((category) {
          return PopupMenuItem<NotificationCategory?>(
            value: category,
            child: Row(
              children: [
                Icon(category.icon, size: 18),
                const SizedBox(width: 8),
                Text(category.title, style: AppTheme.bodyMedium),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReadStatusFilter() {
    String label;
    IconData icon;
    
    switch (widget.readStatusFilter) {
      case true:
        label = 'Lidas';
        icon = Icons.mark_email_read;
        break;
      case false:
        label = 'Não lidas';
        icon = Icons.mark_email_unread;
        break;
      default:
        label = 'Todas';
        icon = Icons.email;
        break;
    }

    return PopupMenuButton<bool?>(
      child: _buildFilterChip(
        label: label,
        icon: icon,
        isActive: widget.readStatusFilter != null,
      ),
      onSelected: widget.onReadStatusChanged,
      itemBuilder: (context) => [
        PopupMenuItem<bool?>(
          value: null,
          child: Row(
            children: [
              const Icon(Icons.email, size: 18),
              const SizedBox(width: 8),
              Text('Todas', style: AppTheme.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem<bool?>(
          value: false,
          child: Row(
            children: [
              const Icon(Icons.mark_email_unread, size: 18),
              const SizedBox(width: 8),
              Text('Não lidas', style: AppTheme.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem<bool?>(
          value: true,
          child: Row(
            children: [
              const Icon(Icons.mark_email_read, size: 18),
              const SizedBox(width: 8),
              Text('Lidas', style: AppTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortFilter() {
    final sortOptions = {
      'sent_at': 'Data de envio',
      'created_at': 'Data de criação',
      'read_at': 'Data de leitura',
      'title': 'Título',
    };

    return PopupMenuButton<String>(
      child: _buildFilterChip(
        label: widget.sortAscending ? 'Crescente' : 'Decrescente',
        icon: widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        isActive: true,
      ),
      onSelected: (sortBy) {
        widget.onSortChanged(sortBy, widget.sortAscending);
      },
      itemBuilder: (context) => [
        ...sortOptions.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Icon(
                  widget.sortBy == entry.key
                      ? (widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                      : Icons.sort,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(entry.value, style: AppTheme.bodyMedium),
                if (widget.sortBy == entry.key) ...[
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      widget.sortAscending ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 16,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSortChanged(entry.key, !widget.sortAscending);
                    },
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAdvancedToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAdvancedFilters = !_showAdvancedFilters;
        });
      },
      child: _buildFilterChip(
        label: 'Avançado',
        icon: _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
        isActive: _showAdvancedFilters || widget.dateFrom != null || widget.dateTo != null,
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.secondaryText.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros Avançados',
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppTheme.spacing),
          _buildDateRangeFilter(),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Período',
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'De',
                date: widget.dateFrom,
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'Até',
                date: widget.dateTo,
                onTap: () => _selectDate(context, false),
              ),
            ),
          ],
        ),
        if (widget.dateFrom != null || widget.dateTo != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => widget.onDateRangeChanged(null, null),
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Limpar período'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.secondaryText.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppTheme.secondaryText),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.bodyMedium.copyWith(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Selecionar',
                    style: AppTheme.bodyMedium.copyWith(
                      color: date != null ? AppTheme.primaryText : AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterActions() {
    final hasActiveFilters = widget.searchQuery.isNotEmpty ||
        widget.selectedCategory != null ||
        widget.readStatusFilter != null ||
        widget.dateFrom != null ||
        widget.dateTo != null;

    return Row(
      children: [
        if (hasActiveFilters) ...[
          TextButton.icon(
            onPressed: widget.onClearFilters,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Limpar filtros'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
          ),
          const Spacer(),
        ],
        Text(
          hasActiveFilters ? 'Filtros ativos' : 'Sem filtros',
          style: AppTheme.bodyMedium.copyWith(
            fontSize: 12,
            color: AppTheme.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppTheme.accentColor : AppTheme.secondaryText.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? Colors.white : AppTheme.secondaryText,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 12,
              color: isActive ? Colors.white : AppTheme.primaryText,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate ? widget.dateFrom : widget.dateTo;
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.accentColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      if (isFromDate) {
        widget.onDateRangeChanged(selectedDate, widget.dateTo);
      } else {
        widget.onDateRangeChanged(widget.dateFrom, selectedDate);
      }
    }
  }
}