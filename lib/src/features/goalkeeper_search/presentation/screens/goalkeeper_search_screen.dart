import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/goalkeeper_search_controller.dart';
import '../../data/models/goalkeeper.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/primary_button.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import 'goalkeeper_details_screen.dart';
import '../widgets/fut_card.dart';

class GoalkeeperSearchScreen extends StatefulWidget {
  const GoalkeeperSearchScreen({super.key});

  @override
  State<GoalkeeperSearchScreen> createState() => _GoalkeeperSearchScreenState();
}

class _GoalkeeperSearchScreenState extends State<GoalkeeperSearchScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _listFadeAnimation;
  String? _expandedGoalkeeperId;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _listFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _headerAnimationController.forward();
    
    // Initialize controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<GoalkeeperSearchController>(context, listen: false);
      controller.initialize().then((_) {
        _listAnimationController.forward();
      });
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
        child: SafeArea(
          child: Consumer<GoalkeeperSearchController>(
            builder: (context, controller, child) {
              return Column(
                children: [
                  _buildHeader(controller),
                  Expanded(
                    child: _buildContent(controller),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GoalkeeperSearchController controller) {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
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
                      Text(
                        'Busca de Guarda-Redes',
                        style: AppTheme.headingLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Encontre o guarda-redes ideal para a sua equipa',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  if (controller.stats.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppTheme.spacing),
                    _buildStatsRow(controller.stats),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.secondaryBackground.withOpacity(0.6),
            AppTheme.secondaryBackground.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.sports_soccer,
            '${stats['total_goalkeepers'] ?? 0}',
            'Guarda-redes',
          ),
          Container(
            width: 1,
            height: 30,
            color: AppTheme.secondaryText.withOpacity(0.3),
          ),
          _buildStatItem(
            Icons.euro,
            '€${(stats['average_price'] ?? 0.0).toStringAsFixed(0)}',
            'Preço médio',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.accentColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(GoalkeeperSearchController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
      child: Column(
        children: [
          _buildSearchSection(controller),
          const SizedBox(height: AppTheme.spacingLarge),
          Expanded(
            child: _buildResultsSection(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(GoalkeeperSearchController controller) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryBackground.withOpacity(0.8),
            AppTheme.secondaryBackground.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Procurar por nome ou cidade...',
            prefixIcon: Icons.search_rounded,
            onChanged: controller.updateSearchQuery,
          ),
          const SizedBox(height: AppTheme.spacing),
          Row(
            children: [
              Expanded(
                child: _buildCityDropdown(controller),
              ),
              const SizedBox(width: AppTheme.spacing),
              _buildFilterButton(controller),
            ],
          ),
          if (controller.hasActiveFilters) ...<Widget>[
            const SizedBox(height: AppTheme.spacing),
            _buildActiveFilters(controller),
          ],
        ],
      ),
    );
  }

  Widget _buildCityDropdown(GoalkeeperSearchController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        hint: Text(
          'Selecionar cidade',
          style: AppTheme.bodyMedium,
        ),
        value: controller.selectedCity,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        dropdownColor: AppTheme.secondaryBackground,
        style: AppTheme.bodyLarge,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: AppTheme.accentColor,
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Todas as cidades'),
          ),
          ...controller.availableCities
              .map((city) => DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  ))
              .toList(),
        ],
        onChanged: controller.updateCityFilter,
      ),
    );
  }

  Widget _buildFilterButton(GoalkeeperSearchController controller) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppTheme.buttonGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          onTap: () => _showFiltersBottomSheet(controller),
          child: const Icon(
            Icons.tune,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilters(GoalkeeperSearchController controller) {
    return Row(
      children: [
        Icon(
          Icons.filter_list,
          color: AppTheme.accentColor,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Filtros ativos',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            controller.clearFilters();
            _searchController.clear();
          },
          child: Text(
            'Limpar',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection(GoalkeeperSearchController controller) {
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

    if (controller.goalkeepers.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _listFadeAnimation,
          child: _buildGoalkeepersList(controller.goalkeepers),
        );
      },
    );
  }

  Widget _buildGoalkeepersList(List<Goalkeeper> goalkeepers) {
    return RefreshIndicator(
      onRefresh: () async {
        final controller = Provider.of<GoalkeeperSearchController>(context, listen: false);
        await controller.refresh();
      },
      color: AppTheme.accentColor,
      backgroundColor: AppTheme.secondaryBackground,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: goalkeepers.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildGoalkeeperCard(goalkeepers[index], index),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGoalkeeperCard(Goalkeeper goalkeeper, int index) {
    final isExpanded = _expandedGoalkeeperId == goalkeeper.id;
    return Align(
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: AppTheme.mediumAnimation,
        curve: Curves.easeInOut,
        height: isExpanded ? 475 : 350,
        width: isExpanded ? 325 : 250,
        child: ExpandableFutCard(
          goalkeeper: goalkeeper,
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedGoalkeeperId = null;
              } else {
                _expandedGoalkeeperId = goalkeeper.id;
              }
            });
          },
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
            Icons.search_off,
            size: 80,
            color: AppTheme.secondaryText.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacing),
          Text(
            'Nenhum guarda-redes encontrado',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os seus filtros de pesquisa',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(GoalkeeperSearchController controller) {
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
            'Erro ao carregar dados',
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
          PrimaryButton(
            text: 'Tentar Novamente',
            onPressed: () => controller.refresh(),
            icon: Icons.refresh,
            width: 200,
          ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet(GoalkeeperSearchController controller) {
    // TODO: Implement advanced filters bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Filtros avançados em breve!'),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showGoalkeeperDetails(Goalkeeper goalkeeper) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoalkeeperDetailsScreen(goalkeeper: goalkeeper),
      ),
    );
  }
}
