import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import '../controllers/user_profile_controller.dart';
import 'edit_profile_screen.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../availability/presentation/screens/availability_management_screen.dart';
import '../widgets/fut_profile_card.dart';
import '../widgets/stats_dashboard.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/achievements_section.dart';

class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
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
    
    // Load profile and start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProfileController>(context, listen: false).getUserProfile();
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
    final controller = Provider.of<UserProfileController>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        child: controller.isLoading
            ? _buildLoadingState()
            : controller.userProfile == null
                ? _buildEmptyState()
                : _buildEnhancedProfileContent(controller, size),
      ),
      floatingActionButton: controller.userProfile != null
          ? _buildAnimatedFAB(controller)
          : null,
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
              Icons.sports_soccer,
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
            'Carregando perfil do jogador...',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(75),
              border: Border.all(
                color: const Color(0xFFFF8C00).withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Icon(
              Icons.person_off_outlined,
              size: 80,
              color: AppTheme.secondaryText.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Perfil não encontrado',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Não foi possível carregar as informações do jogador',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedProfileContent(UserProfileController controller, Size size) {
    return AnimatedBuilder(
      animation: _mainAnimationController,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacing),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Main FUT Card
                _buildFUTCard(controller),
                const SizedBox(height: AppTheme.spacingLarge),
                
                // Stats Dashboard
                _buildStatsDashboard(controller),
                const SizedBox(height: AppTheme.spacingLarge),
                
                // Information Cards
                _buildInformationSection(controller),
                const SizedBox(height: AppTheme.spacingLarge),
                
                // Achievements Section
                _buildAchievementsSection(controller),
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
        'Perfil do Jogador',
        style: AppTheme.headingMedium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/notifications');
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.primaryText,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            _showSettingsMenu(context);
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppTheme.primaryText,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
  
  Widget _buildFUTCard(UserProfileController controller) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: FUTProfileCard(
            userProfile: controller.userProfile!,
          ),
        );
      },
    );
  }
  
  Widget _buildStatsDashboard(UserProfileController controller) {
    return StatsDashboard(
      userProfile: controller.userProfile!,
    );
  }
  
  Widget _buildInformationSection(UserProfileController controller) {
    return Column(
      children: [
        ProfileInfoCard(
          title: 'Informações Pessoais',
          icon: Icons.person_outline,
          userProfile: controller.userProfile!,
        ),
        const SizedBox(height: AppTheme.spacing),
        ProfileInfoCard(
          title: 'Informações Desportivas',
          icon: Icons.sports_soccer,
          userProfile: controller.userProfile!,
          isCareer: true,
        ),
        if (controller.userProfile!.isGoalkeeper) ...[
          const SizedBox(height: AppTheme.spacing),
          _buildAvailabilityCard(),
        ],
      ],
    );
  }
  
  Widget _buildAchievementsSection(UserProfileController controller) {
    return AchievementsSection(
      userProfile: controller.userProfile!,
    );
  }
  
  Widget _buildAvailabilityCard() {
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const AvailabilityManagementScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOutCubic,
                              )),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: Padding(
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
                                  Icons.sports_soccer,
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
                                      'Minha Disponibilidade',
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
                                      'Pronto para defender!',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 20,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(1, 1),
                                      blurRadius: 2,
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
                                        Icons.sports_handball,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Configure seus horários e torne-se o guarda-redes que todos procuram',
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
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _buildQuickStat('Próximas', '3', Icons.event_available),
                                    const SizedBox(width: 16),
                                    _buildQuickStat('Esta Semana', '8h', Icons.access_time),
                                    const SizedBox(width: 16),
                                    _buildQuickStat('Rating', '4.9', Icons.star),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedFAB(UserProfileController controller) {
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
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        EditProfileScreen(userProfile: controller.userProfile!),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        )),
                        child: child,
                      );
                    },
                  ),
                );
              },
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                'Editar Perfil',
                style: AppTheme.buttonText.copyWith(fontSize: 14),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryText.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Configurações',
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: 24),
                  _buildSettingsOption(
                    icon: Icons.notifications_outlined,
                    title: 'Notificações',
                    subtitle: 'Gerir notificações push',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/notifications');
                    },
                  ),
                  _buildSettingsOption(
                    icon: Icons.logout_outlined,
                    title: 'Terminar Sessão',
                    subtitle: 'Sair da aplicação',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showLogoutConfirmation(context);
                    },
                    isDestructive: true,
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppTheme.errorColor.withOpacity(0.1)
                : const Color(0xFFFF8C00).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppTheme.errorColor : const Color(0xFFFF8C00),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppTheme.errorColor : AppTheme.primaryText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.bodyMedium,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Terminar Sessão',
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Tem a certeza que quer terminar a sessão?',
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
            onPressed: () async {
              Navigator.of(context).pop();
              await Supabase.instance.client.auth.signOut();
            },
            child: Text(
              'Terminar Sessão',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
