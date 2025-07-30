import 'package:flutter/material.dart';
import '../../../../features/auth/presentation/theme/app_theme.dart';

enum FilterType { city, availability, markerType, surface, size }

class EnhancedFilterDialog extends StatefulWidget {
  final List<String> availableCities;
  final String? selectedCity;
  final String? selectedAvailability;
  final List<String> availableSurfaces;
  final List<String> selectedSurfaces;
  final List<String> availableSizes;
  final List<String> selectedSizes;
  final Function(String) onCitySelected;
  final Function(String) onAvailabilitySelected;
  final Function(List<String>) onSurfacesSelected;
  final Function(List<String>) onSizesSelected;
  final VoidCallback onClearFilter;
  final Function(Set<String>) onMarkerTypesSelected;

  const EnhancedFilterDialog({
    super.key,
    required this.availableCities,
    this.selectedCity,
    this.selectedAvailability,
    required this.availableSurfaces,
    required this.selectedSurfaces,
    required this.availableSizes,
    required this.selectedSizes,
    required this.onCitySelected,
    required this.onAvailabilitySelected,
    required this.onSurfacesSelected,
    required this.onSizesSelected,
    required this.onClearFilter,
    required this.onMarkerTypesSelected,
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
  List<String> _tempSelectedSurfaces = [];
  List<String> _tempSelectedSizes = [];
  FilterType _currentFilter = FilterType.city;
  final Set<String> _selectedMarkerTypes = {'Players', 'Fields', 'Goalkeepers'};

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
    _tempSelectedSurfaces = List.from(widget.selectedSurfaces);
    _tempSelectedSizes = List.from(widget.selectedSizes);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
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
    
    // Apply surface and size filters
    widget.onSurfacesSelected(_tempSelectedSurfaces);
    widget.onSizesSelected(_tempSelectedSizes);
    
    // Apply marker type filters
    widget.onMarkerTypesSelected(_selectedMarkerTypes);
    
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
                  maxHeight: 650,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.authBackground,
                  borderRadius: BorderRadius.circular(24),
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
        gradient: AppTheme.authPrimaryGradient,
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
          Expanded(
            child: Text(
              'Filtros Avançados',
              style: AppTheme.authHeadingSmall.copyWith(
                color: Colors.white,
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
      height: 60,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTabButton(
            'Cidade',
            Icons.location_city,
            FilterType.city,
            _currentFilter == FilterType.city,
          ),
          _buildTabButton(
            'Disponibilidade',
            Icons.access_time,
            FilterType.availability,
            _currentFilter == FilterType.availability,
          ),
          _buildTabButton(
            'Tipo',
            Icons.public,
            FilterType.markerType,
            _currentFilter == FilterType.markerType,
          ),
          _buildTabButton(
            'Superfície',
            Icons.grass,
            FilterType.surface,
            _currentFilter == FilterType.surface,
          ),
          _buildTabButton(
            'Tamanho',
            Icons.fullscreen,
            FilterType.size,
            _currentFilter == FilterType.size,
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.authPrimaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.authTextSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.authTextSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _getCurrentFilterContent(),
      ),
    );
  }

  Widget _getCurrentFilterContent() {
    switch (_currentFilter) {
      case FilterType.city:
        return _buildCityFilter();
      case FilterType.availability:
        return _buildAvailabilityFilter();
      case FilterType.markerType:
        return _buildMarkerTypeFilter();
      case FilterType.surface:
        return _buildSurfaceFilter();
      case FilterType.size:
        return _buildSizeFilter();
    }
  }

  Widget _buildCityFilter() {
    // Implement searchable dropdown for cities
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return widget.availableCities.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() {
                _tempSelectedCity = selection;
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Pesquisar cidade...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.authTextSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.authInputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.authInputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.authPrimaryGreen, width: 2),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: widget.availableCities.isEmpty
              ? _buildEmptyState('Nenhuma cidade disponível', Icons.location_off_outlined)
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.availableCities.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildFilterOption(
                        title: 'Todas as cidades',
                        subtitle: 'Mostrar todos os campos e jogadores',
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
                      subtitle: 'Filtrar por $city',
                      icon: Icons.location_city,
                      isSelected: _tempSelectedCity == city,
                      onTap: () {
                        setState(() {
                          _tempSelectedCity = city;
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilter() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _availabilityOptions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildFilterOption(
            title: 'Qualquer disponibilidade',
            subtitle: 'Mostrar todas as disponibilidades',
            icon: Icons.event_available,
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
          icon: Icons.access_time_filled,
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
        return 'Disponibilidade imediata';
      case 'Disponível hoje':
        return 'Disponível nas próximas 24 horas';
      case 'Disponível esta semana':
        return 'Disponível nos próximos 7 dias';
      case 'Sempre disponível':
        return 'Disponível a qualquer momento';
      default:
        return '';
    }
  }

  Widget _buildMarkerTypeFilter() {
    final markerTypes = {
      'Jogadores': Icons.person,
      'Campos': Icons.sports_soccer,
      'Guarda-redes': Icons.sports_handball,
    };

    return ListView( 
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: markerTypes.entries.map((entry) {
        final type = entry.key;
        final icon = entry.value;
        final isSelected = _selectedMarkerTypes.contains(type);

        return _buildFilterOption(
          title: type,
          subtitle: 'Mostrar ${type.toLowerCase()} no mapa',
          icon: icon,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedMarkerTypes.remove(type);
              } else {
                _selectedMarkerTypes.add(type);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSurfaceFilter() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: widget.availableSurfaces.map((surface) {
        final isSelected = _tempSelectedSurfaces.contains(surface);
        return _buildFilterOption(
          title: surface,
          subtitle: 'Filtrar por tipo de relva',
          icon: Icons.grass,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                _tempSelectedSurfaces.remove(surface);
              } else {
                _tempSelectedSurfaces.add(surface);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSizeFilter() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: widget.availableSizes.map((size) {
        final isSelected = _tempSelectedSizes.contains(size);
        return _buildFilterOption(
          title: size,
          subtitle: 'Filtrar por tamanho do campo',
          icon: Icons.fullscreen,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                _tempSelectedSizes.remove(size);
              } else {
                _tempSelectedSizes.add(size);
              }
            });
          },
        );
      }).toList(),
    );
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
                  ? AppTheme.authPrimaryGreen.withOpacity(0.1)
                  : AppTheme.authCardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.authPrimaryGreen
                    : AppTheme.authInputBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.authPrimaryGreen.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.authPrimaryGreen
                        : AppTheme.authInputBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppTheme.authTextSecondary,
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
                        style: AppTheme.authBodyLarge.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.authBodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.authPrimaryGreen,
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
            color: AppTheme.authTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.authBodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.authCardBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _tempSelectedCity = null;
                _tempSelectedAvailability = null;
                _selectedMarkerTypes.clear();
              });
            },
            child: Text(
              'Limpar',
              style: AppTheme.authLinkText.copyWith(
                color: AppTheme.authError,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _handleApplyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.authPrimaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Text(
              'Aplicar Filtros',
              style: AppTheme.authButtonText,
            ),
          ),
        ],
      ),
    );
  }
}
