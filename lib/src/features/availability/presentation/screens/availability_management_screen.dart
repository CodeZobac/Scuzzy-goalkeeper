import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/availability_controller.dart';
import '../widgets/availability_form_dialog.dart';
import '../widgets/availability_card_widget.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class AvailabilityManagementScreen extends StatelessWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AvailabilityController(),
      child: const _AvailabilityManagementContent(),
    );
  }
}

class _AvailabilityManagementContent extends StatefulWidget {
  const _AvailabilityManagementContent();

  @override
  State<_AvailabilityManagementContent> createState() => _AvailabilityManagementContentState();
}

class _AvailabilityManagementContentState extends State<_AvailabilityManagementContent>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _fabAnimationController;
  
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Setup animations
    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOut,
    ));
    
    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    // Load availabilities and start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AvailabilityController>(context, listen: false).loadAvailabilities();
      _startAnimations();
    });
  }
  
  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _mainAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _cardAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 600));
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _cardAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: Consumer<AvailabilityController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.availabilities.isEmpty) {
              return _buildLoadingState();
            }
            
            return _buildEnhancedContent(controller);
          },
        ),
      ),
      floatingActionButton: _buildAnimatedFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8C00), Color(0xFFFF7F00)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C00).withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(
              Icons.schedule_outlined,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Carregando disponibilidades...',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedContent(AvailabilityController controller) {
    return AnimatedBuilder(
      animation: _mainAnimationController,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacing),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero Header Section
                _buildHeroHeader(controller),
                const SizedBox(height: AppTheme.spacingLarge),
                
                // Quick Stats Section
                _buildQuickStatsSection(controller),
                const SizedBox(height: AppTheme.spacingLarge),
                
                // Availability List or Empty State
                controller.availabilities.isEmpty
                    ? _buildEnhancedEmptyState()
                    : _buildAvailabilityList(controller),
                
                const SizedBox(height: 100), // Space for FAB
              ]),
            ),
          ),
        ],
      ),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
    );
  }
  
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      title: Text(
        'Minha Disponibilidade',
        style: AppTheme.headingMedium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBackground.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.primaryText,
            size: 20,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            _showHelpDialog(context);
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.help_outline,
              color: AppTheme.primaryText,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
  
  Widget _buildHeroHeader(AvailabilityController controller) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8C00), Color(0xFFFF7F00)],
                stops: [0.0, 1.0],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C00).withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFFF8C00).withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background Pattern
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                // Floating Orbs
                Positioned(
                  top: -20,
                  right: 20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -10,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Main Content
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.schedule_outlined,
                              color: Colors.white,
                              size: 32,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gerir Disponibilidade',
                                  style: AppTheme.headingMedium.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(1, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Configure seus horários livres',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Enhanced Information Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Defina quando está disponível para jogar como guarda-redes',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStatsSection(AvailabilityController controller) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${controller.availabilities.length}',
                  Icons.event_available,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Esta Semana',
                  '${_getThisWeekCount(controller)}',
                  Icons.today,
                  const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Próximo',
                  '${_getUpcomingCount(controller)}',
                  Icons.schedule,
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _getThisWeekCount(AvailabilityController controller) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return controller.availabilities.where((availability) {
      return availability.day.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             availability.day.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).length;
  }

  int _getUpcomingCount(AvailabilityController controller) {
    final now = DateTime.now();
    return controller.availabilities.where((availability) {
      return availability.day.isAfter(now);
    }).length;
  }
  
  Widget _buildEnhancedEmptyState() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFF8C00).withOpacity(0.1),
                        const Color(0xFFFF7F00).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(75),
                    border: Border.all(
                      color: const Color(0xFFFF8C00).withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8C00).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.event_available_outlined,
                    size: 80,
                    color: const Color(0xFFFF8C00).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Nenhuma Disponibilidade',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Adicione seus horários disponíveis\npara que jogadores possam agendá-lo',
                  style: AppTheme.bodyMedium.copyWith(
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => _showAddAvailabilityDialog(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Adicionar Primeira Disponibilidade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFFFF8C00).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAvailabilityList(AvailabilityController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suas Disponibilidades',
          style: AppTheme.headingMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...controller.availabilities.asMap().entries.map((entry) {
          final index = entry.key;
          final availability = entry.value;
          return AnimatedBuilder(
            animation: _cardAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (1 - _cardScaleAnimation.value) * 20 * (index + 1)),
                child: Opacity(
                  opacity: _cardScaleAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing),
                    child: AvailabilityCardWidget(
                      availability: availability,
                      onDelete: () => _confirmDelete(context, availability.id!),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
  
  Widget _buildAnimatedFAB() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 35,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8C00), Color(0xFFFF7F00)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C00).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _showAddAvailabilityDialog(context),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_outlined),
              label: Text(
                'Adicionar Horário',
                style: AppTheme.buttonText.copyWith(fontSize: 14),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showAddAvailabilityDialog(BuildContext context) {
    final controller = Provider.of<AvailabilityController>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AvailabilityFormDialog(
        controller: controller,
        onSave: (availability) async {
          final success = await controller.createAvailability(availability);
          
          if (!mounted) return;
          
          if (success) {
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Disponibilidade adicionada com sucesso'),
                backgroundColor: AppTheme.successColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(controller.errorMessage ?? 'Erro ao adicionar disponibilidade'),
                backgroundColor: AppTheme.errorColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, String availabilityId) {
    final controller = Provider.of<AvailabilityController>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Confirmar Exclusão',
          style: AppTheme.headingMedium.copyWith(fontSize: 18),
        ),
        content: Text(
          'Tem certeza que deseja remover esta disponibilidade?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancelar',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.secondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await controller.deleteAvailability(availabilityId);
              
              if (!mounted) return;
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Disponibilidade removida com sucesso'),
                    backgroundColor: AppTheme.successColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(controller.errorMessage ?? 'Erro ao remover disponibilidade'),
                    backgroundColor: AppTheme.errorColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFF7F00)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Ajuda',
              style: AppTheme.headingMedium.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como funciona:',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '• Adicione seus horários disponíveis\n• Jogadores poderão vê-lo nos resultados de busca\n• Você receberá notificações de convites\n• Gerencie suas disponibilidades facilmente',
              style: AppTheme.bodyMedium.copyWith(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Entendi',
              style: AppTheme.bodyMedium.copyWith(
                color: const Color(0xFFFF8C00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
