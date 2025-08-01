import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import '../controllers/user_profile_controller.dart';
import 'edit_profile_screen.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../availability/presentation/screens/availability_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _fabAnimationController;
  
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
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
    
    _cardAnimationController = AnimationController(
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
    
    _cardSlideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _cardFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
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
    
    // Load profile and start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProfileController>(context, listen: false).getUserProfile();
      _startAnimations();
    });
  }
  
  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _cardAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<UserProfileController>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: controller.isLoading
            ? _buildLoadingState()
            : controller.userProfile == null
                ? _buildEmptyState()
                : _buildProfileContent(controller, size),
      ),
      floatingActionButton: controller.userProfile != null
          ? _buildAnimatedFAB(controller)
          : null,
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
              Icons.person,
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
            'A carregar perfil...',
            style: AppTheme.bodyMedium,
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
              Icons.person_off_outlined,
              size: 60,
              color: AppTheme.secondaryText.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Perfil não encontrado',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Não foi possível carregar as informações do perfil',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileContent(UserProfileController controller, Size size) {
    return CustomScrollView(
      slivers: [
        _buildAnimatedHeader(controller, size),
        SliverPadding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildProfileCards(controller),
              const SizedBox(height: 100), // Space for FAB
            ]),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnimatedHeader(UserProfileController controller, Size size) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: AppTheme.authPrimaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.authPrimaryGreen.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              _showSettingsMenu(context);
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
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
                      _buildAnimatedAvatar(controller),
                      const SizedBox(height: 16),
                      _buildNameAndStatus(controller),
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
  
  Widget _buildAnimatedAvatar(UserProfileController controller) {
    return Hero(
      tag: 'profile-avatar',
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: AppTheme.buttonGradient,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                controller.userProfile!.name.isNotEmpty
                    ? controller.userProfile!.name[0].toUpperCase()
                    : 'U',
                style: AppTheme.headingLarge.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (controller.userProfile!.isGoalkeeper)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNameAndStatus(UserProfileController controller) {
    return Column(
      children: [
        Text(
          controller.userProfile!.name,
          style: AppTheme.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: controller.userProfile!.isGoalkeeper
                  ? [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)]
                  : [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (controller.userProfile!.isGoalkeeper
                        ? AppTheme.successColor
                        : AppTheme.accentColor)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            controller.userProfile!.isGoalkeeper ? 'Guarda-Redes' : 'Jogador',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfileCards(UserProfileController controller) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value),
          child: Opacity(
            opacity: _cardFadeAnimation.value,
            child: Column(
              children: [
                _buildInfoCard(controller),
                const SizedBox(height: AppTheme.spacing),
                _buildStatsCard(controller),
                const SizedBox(height: AppTheme.spacing),
                _buildLocationCard(controller),
                if (controller.userProfile!.isGoalkeeper) ...[
                  const SizedBox(height: AppTheme.spacing),
                  _buildAvailabilityCard(controller),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInfoCard(UserProfileController controller) {
    return _buildCard(
      'Informações Pessoais',
      Icons.person_outline,
      [
        _buildInfoRow('Género', controller.userProfile!.gender ?? 'Não especificado', Icons.wc),
        _buildInfoRow(
          'Data de Nascimento',
          controller.userProfile!.birthDate != null
              ? _formatDate(controller.userProfile!.birthDate!)
              : 'Não especificada',
          Icons.cake_outlined,
        ),
        _buildInfoRow('Nacionalidade', controller.userProfile!.nationality ?? 'Não especificada', Icons.flag_outlined),
      ],
    );
  }
  
  Widget _buildStatsCard(UserProfileController controller) {
    return _buildCard(
      'Informações Desportivas',
      Icons.sports_soccer,
      [
        _buildInfoRow('Clube', controller.userProfile!.club ?? 'Sem clube', Icons.groups_outlined),
        if (controller.userProfile!.pricePerGame != null)
          _buildInfoRow(
            'Preço por Jogo',
            '€${controller.userProfile!.pricePerGame!.toStringAsFixed(2)}',
            Icons.euro_outlined,
          ),
        _buildInfoRow(
          'Posição',
          controller.userProfile!.isGoalkeeper ? 'Guarda-Redes' : 'Jogador de Campo',
          controller.userProfile!.isGoalkeeper ? Icons.sports_soccer : Icons.directions_run,
        ),
      ],
    );
  }
  
  Widget _buildLocationCard(UserProfileController controller) {
    return _buildCard(
      'Localização',
      Icons.location_on_outlined,
      [
        _buildInfoRow('Cidade', controller.userProfile!.city ?? 'Não especificada', Icons.location_city_outlined),
        _buildInfoRow('País', controller.userProfile!.country ?? 'Não especificado', Icons.public_outlined),
      ],
    );
  }
  
  Widget _buildAvailabilityCard(UserProfileController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.successColor.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const AvailabilityManagementScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  
                  var tween = Tween(begin: begin, end: end).chain(
                    CurveTween(curve: curve),
                  );
                  
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Minha Disponibilidade',
                            style: AppTheme.headingMedium.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gerencie seus horários disponíveis',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.successColor,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Defina quando está disponível para jogos e permita que jogadores agendem sessões',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.accentColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedFAB(UserProfileController controller) {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Transform.rotate(
            angle: _fabRotationAnimation.value * 2 * math.pi,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        EditProfileScreen(userProfile: controller.userProfile!),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      
                      var tween = Tween(begin: begin, end: end).chain(
                        CurveTween(curve: curve),
                      );
                      
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              elevation: 8,
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
  
  String _formatDate(DateTime date) {
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.authCardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.authTextSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Configurações',
                    style: AppTheme.authHeadingMedium.copyWith(
                      color: AppTheme.authTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSettingsOption(
                    icon: Icons.notifications_outlined,
                    title: 'Notificações',
                    subtitle: 'Ver notificações recebidas',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/notifications');
                    },
                  ),
                  _buildSettingsOption(
                    icon: Icons.tune,
                    title: 'Preferências de Notificação',
                    subtitle: 'Gerir tipos de notificações',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/notification-preferences');
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.authBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.authInputBorder.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isDestructive
                ? LinearGradient(
                    colors: [
                      AppTheme.authError.withOpacity(0.1),
                      AppTheme.authError.withOpacity(0.05),
                    ],
                  )
                : AppTheme.authPrimaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: (isDestructive ? AppTheme.authError : AppTheme.authPrimaryGreen)
                    .withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppTheme.authError : Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTheme.authBodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppTheme.authError : AppTheme.authTextPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.authBodyMedium.copyWith(
            color: AppTheme.authTextSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isDestructive ? AppTheme.authError : AppTheme.authPrimaryGreen,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.authCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.authError.withOpacity(0.1),
                    AppTheme.authError.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout_outlined,
                color: AppTheme.authError,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Terminar Sessão',
              style: AppTheme.authHeadingSmall.copyWith(
                color: AppTheme.authTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Tem a certeza que quer terminar a sessão?',
          style: AppTheme.authBodyMedium.copyWith(
            color: AppTheme.authTextSecondary,
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.authInputBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Cancelar',
                style: AppTheme.authBodyMedium.copyWith(
                  color: AppTheme.authTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.authError,
                  AppTheme.authError.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.authError.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Sign out using Supabase auth
                await Supabase.instance.client.auth.signOut();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Terminar Sessão',
                style: AppTheme.authButtonText.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
