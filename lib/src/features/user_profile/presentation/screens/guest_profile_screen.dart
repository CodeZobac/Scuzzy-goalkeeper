import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../auth/presentation/theme/app_theme.dart';

class GuestProfileScreen extends StatefulWidget {
  const GuestProfileScreen({super.key});

  @override
  State<GuestProfileScreen> createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends State<GuestProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _buttonAnimationController;
  
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonRotationAnimation;

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
    
    _buttonAnimationController = AnimationController(
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
    
    _buttonScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _buttonRotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });
  }
  
  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _mainAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _cardAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 600));
    _buttonAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _cardAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildGuestProfileContent(),
    );
  }

  Widget _buildGuestProfileContent() {
    return AnimatedBuilder(
      animation: _mainAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 40),
                      _buildGuestAvatar(),
                      const SizedBox(height: AppTheme.spacingLarge),
                      _buildWelcomeMessage(),
                      const SizedBox(height: AppTheme.spacingLarge),
                      _buildFeatureCards(),
                      const SizedBox(height: AppTheme.spacingLarge),
                      _buildRegistrationCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildGuestAvatar() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.authPrimaryGradient,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.authPrimaryGreen.withOpacity(0.4),
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
              child: const Icon(
                Icons.person_outline,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildWelcomeMessage() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Column(
            children: [
              Text(
                'Não tem sessão iniciada',
                style: AppTheme.authHeadingMedium.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Crie uma conta para aceder a recursos exclusivos e personalizar o seu perfil',
                style: AppTheme.authBodyMedium.copyWith(
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFeatureCards() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Column(
            children: [
              _buildFeatureCard(
                icon: Icons.sports_soccer,
                title: 'Participe em Jogos',
                description: 'Encontre e participe em jogos na sua região',
                color: AppTheme.authPrimaryGreen,
              ),
              const SizedBox(height: AppTheme.spacing),
              _buildFeatureCard(
                icon: Icons.person_search,
                title: 'Contrate Guarda-Redes',
                description: 'Encontre guarda-redes profissionais disponíveis',
                color: AppTheme.authLightGreen,
              ),
              const SizedBox(height: AppTheme.spacing),
              _buildFeatureCard(
                icon: Icons.account_circle,
                title: 'Perfil Personalizado',
                description: 'Crie o seu perfil e mostre as suas habilidades',
                color: AppTheme.authSecondaryGreen,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.authCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.authBodyMedium.copyWith(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRegistrationCard() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.authPrimaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.authPrimaryGreen.withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppTheme.authPrimaryGreen.withOpacity(0.2),
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
                      // Header
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
                              Icons.star,
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
                                  'Junte-se à Comunidade',
                                  style: AppTheme.authHeadingMedium.copyWith(
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
                                  'Desbloqueie todas as funcionalidades!',
                                  style: AppTheme.authBodyMedium.copyWith(
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
                      // Benefits Section
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
                                    Icons.sports_soccer,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Aceda a jogos exclusivos, contrate guarda-redes profissionais e conecte-se com jogadores da sua região',
                                    style: AppTheme.authBodyMedium.copyWith(
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
                                _buildBenefit('Jogos', Icons.sports_soccer),
                                const SizedBox(width: 16),
                                _buildBenefit('Guarda-Redes', Icons.sports_handball),
                                const SizedBox(width: 16),
                                _buildBenefit('Comunidade', Icons.group),
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

  Widget _buildBenefit(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.authBodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
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

  Widget _buildAnimatedRegisterButton() {
    return AnimatedBuilder(
      animation: _buttonAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 35,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: AppTheme.authButtonGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.authPrimaryGreen.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _navigateToRegister,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Criar Conta',
                        style: AppTheme.authButtonText.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _buttonAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAuthButton(
                text: 'Entrar',
                icon: Icons.login,
                onTap: _navigateToLogin,
                isPrimary: false,
              ),
              const SizedBox(width: 16),
              _buildAuthButton(
                text: 'Criar Conta',
                icon: Icons.person_add,
                onTap: _navigateToRegister,
                isPrimary: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = true,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: isPrimary ? AppTheme.authButtonGradient : null,
          color: isPrimary ? null : AppTheme.authCardBackground,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppTheme.authPrimaryGreen.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isPrimary ? Colors.white : AppTheme.authPrimaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: AppTheme.authButtonText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPrimary ? Colors.white : AppTheme.authPrimaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.of(context).pushNamed('/signup');
  }

  void _navigateToLogin() {
    Navigator.of(context).pushNamed('/signin');
  }
}
