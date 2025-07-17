import 'package:flutter/material.dart';

enum FilterType { city, availability }

class EnhancedFilterDialog extends StatefulWidget {
  final List<String> availableCities;
  final String? selectedCity;
  final String? selectedAvailability;
  final Function(String) onCitySelected;
  final Function(String) onAvailabilitySelected;
  final VoidCallback onClearFilter;

  const EnhancedFilterDialog({
    super.key,
    required this.availableCities,
    this.selectedCity,
    this.selectedAvailability,
    required this.onCitySelected,
    required this.onAvailabilitySelected,
    required this.onClearFilter,
  });

  @override
  State<EnhancedFilterDialog> createState() => _EnhancedFilterDialogState();
}

class _EnhancedFilterDialogState extends State<EnhancedFilterDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  String? _tempSelectedCity;
  String? _tempSelectedAvailability;
  FilterType _currentFilter = FilterType.city;

  final List<String> _availabilityOptions = [
    'Disponível agora',
    'Disponível hoje',
    'Disponível esta semana',
    'Sempre disponível',
  ];

  @override
  void initState() {
    super.initState();
    _tempSelectedCity = widget.selectedCity;
    _tempSelectedAvailability = widget.selectedAvailability;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleApplyFilters() {
    // Apply city filter
    if (_tempSelectedCity != null) {
      widget.onCitySelected(_tempSelectedCity!);
    }
    
    // Apply availability filter
    if (_tempSelectedAvailability != null) {
      widget.onAvailabilitySelected(_tempSelectedAvailability!);
    }
    
    // If no filters selected, clear all
    if (_tempSelectedCity == null && _tempSelectedAvailability == null) {
      widget.onClearFilter();
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildFilterTabs(),
                    _buildFilterContent(),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Filtros',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'Cidade',
              Icons.location_city,
              FilterType.city,
              _currentFilter == FilterType.city,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Disponibilidade',
              Icons.access_time,
              FilterType.availability,
              _currentFilter == FilterType.availability,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, FilterType filterType, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentFilter = filterType;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    return Flexible(
      child: _currentFilter == FilterType.city
          ? _buildCityFilter()
          : _buildAvailabilityFilter(),
    );
  }

  Widget _buildCityFilter() {
    return widget.availableCities.isEmpty
        ? _buildEmptyState('Nenhuma cidade disponível', Icons.location_off)
        : ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.availableCities.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildFilterOption(
                  title: 'Todas as cidades',
                  subtitle: 'Mostrar todos os campos',
                  icon: Icons.public,
                  isSelected: _tempSelectedCity == null,
                  onTap: () {
                    setState(() {
                      _tempSelectedCity = null;
                    });
                  },
                );
              }
              
              final city = widget.availableCities[index - 1];
              return _buildFilterOption(
                title: city,
                subtitle: 'Campos em $city',
                icon: Icons.location_city,
                isSelected: _tempSelectedCity == city,
                onTap: () {
                  setState(() {
                    _tempSelectedCity = city;
                  });
                },
              );
            },
          );
  }

  Widget _buildAvailabilityFilter() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _availabilityOptions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildFilterOption(
            title: 'Qualquer disponibilidade',
            subtitle: 'Mostrar todos os campos',
            icon: Icons.schedule,
            isSelected: _tempSelectedAvailability == null,
            onTap: () {
              setState(() {
                _tempSelectedAvailability = null;
              });
            },
          );
        }
        
        final availability = _availabilityOptions[index - 1];
        return _buildFilterOption(
          title: availability,
          subtitle: _getAvailabilitySubtitle(availability),
          icon: Icons.access_time,
          isSelected: _tempSelectedAvailability == availability,
          onTap: () {
            setState(() {
              _tempSelectedAvailability = availability;
            });
          },
        );
      },
    );
  }

  String _getAvailabilitySubtitle(String availability) {
    switch (availability) {
      case 'Disponível agora':
        return 'Campos livres neste momento';
      case 'Disponível hoje':
        return 'Campos com horários hoje';
      case 'Disponível esta semana':
        return 'Campos com horários na semana';
      case 'Sempre disponível':
        return 'Campos sempre abertos';
      default:
        return '';
    }
  }

  Widget _buildFilterOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6C5CE7).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6C5CE7)
                    : Colors.grey.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6C5CE7)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C5CE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_tempSelectedCity != null || _tempSelectedAvailability != null)
                  Text(
                    'Filtros ativos:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (_tempSelectedCity != null)
                  Text(
                    '• $_tempSelectedCity',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (_tempSelectedAvailability != null)
                  Text(
                    '• $_tempSelectedAvailability',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (_tempSelectedCity == null && _tempSelectedAvailability == null)
                  Text(
                    'Nenhum filtro selecionado',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleApplyFilters,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Aplicar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
