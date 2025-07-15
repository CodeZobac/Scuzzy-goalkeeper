import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

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
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late AnimationController _fabAnimationController;
  
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _listSlideAnimation;
  late Animation<double> _listFadeAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Setup animations
    _headerSlideAnimation = Tween<double>(
      begin: -100,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _headerFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    ));
    
    _listSlideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _listFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeOut,
    ));
    
    _fabScaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _fabRotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Load availabilities and start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AvailabilityController>(context, listen: false).loadAvailabilities();
      _startAnimations();
    });
  }
  
  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _listAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _fabAnimationController.dispose();
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
        child: Consumer<AvailabilityController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.availabilities.isEmpty) {
              return _buildLoadingState();
            }
            
            return _buildContent(controller);
          },
        ),
      ),
      floatingActionButton: _buildAnimatedFAB(),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.buttonGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.schedule,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando disponibilidades...',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(AvailabilityController controller) {
    return CustomScrollView(
      slivers: [
        _buildAnimatedHeader(),
        SliverPadding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          sliver: controller.availabilities.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : _buildAvailabilityList(controller),
        ),
        // Space for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }
  
  Widget _buildAnimatedHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: AnimatedBuilder(
        animation: _headerAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _headerSlideAnimation.value),
            child: Opacity(
              opacity: _headerFadeAnimation.value,
              child: FlexibleSpaceBar(
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.buttonGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.schedule,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Minha Disponibilidade',
                        style: AppTheme.headingMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gerencie seus horários disponíveis',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _listSlideAnimation.value),
          child: Opacity(
            opacity: _listFadeAnimation.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBackground.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppTheme.accentColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.event_available_outlined,
                      size: 60,
                      color: AppTheme.secondaryText.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nenhuma disponibilidade',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione seus horários disponíveis\npara que jogadores possam agendá-lo',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showAddAvailabilityDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Disponibilidade'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAvailabilityList(AvailabilityController controller) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final availability = controller.availabilities[index];
          return AnimatedBuilder(
            animation: _listAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _listSlideAnimation.value * (index + 1) * 0.1),
                child: Opacity(
                  opacity: _listFadeAnimation.value,
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
        },
        childCount: controller.availabilities.length,
      ),
    );
  }
  
  Widget _buildAnimatedFAB() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Transform.rotate(
            angle: _fabRotationAnimation.value * 2 * math.pi,
            child: FloatingActionButton.extended(
              onPressed: () => _showAddAvailabilityDialog(context),
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              elevation: 8,
              icon: const Icon(Icons.add),
              label: Text(
                'Adicionar',
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
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(controller.errorMessage ?? 'Erro ao adicionar disponibilidade'),
                backgroundColor: AppTheme.errorColor,
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
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(controller.errorMessage ?? 'Erro ao remover disponibilidade'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
