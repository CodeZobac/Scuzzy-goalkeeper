import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/user_profile/data/models/user_profile.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class AchievementsSection extends StatefulWidget {
  final UserProfile userProfile;

  const AchievementsSection({
    super.key,
    required this.userProfile,
  });

  @override
  State<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<AchievementsSection>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _badgeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    final achievements = _getAchievements();
    _badgeAnimations = List.generate(
      achievements.length,
      (index) => Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          (index + 1) * 0.15,
          curve: Curves.elasticOut,
        ),
      )),
    );

    // Start animation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getAchievements() {
    final achievements = <Map<String, dynamic>>[];
    
    // Profile completion achievement
    if (_getProfileCompletionPercentage() >= 100) {
      achievements.add({
        'title': 'Perfil Completo',
        'description': 'Completou todas as informações do perfil',
        'icon': Icons.account_circle,
        'color': AppTheme.successColor,
        'isUnlocked': true,
        'rarity': 'common',
      });
    }

    // Goalkeeper specific achievements
    if (widget.userProfile.isGoalkeeper) {
      achievements.add({
        'title': 'Guardião',
        'description': 'Registado como guarda-redes',
        'icon': Icons.sports_soccer,
        'color': AppTheme.accentColor,
        'isUnlocked': true,
        'rarity': 'rare',
      });

      if (widget.userProfile.pricePerGame != null) {
        achievements.add({
          'title': 'Profissional',
          'description': 'Definiu preço por jogo',
          'icon': Icons.euro,
          'color': const Color(0xFFFFD700),
          'isUnlocked': true,
          'rarity': 'epic',
        });
      }
    }

    // Club achievement
    if (widget.userProfile.club != null) {
      achievements.add({
        'title': 'Membro de Clube',
        'description': 'Associado a um clube',
        'icon': Icons.groups,
        'color': AppTheme.successColor,
        'isUnlocked': true,
        'rarity': 'common',
      });
    }

    // Location achievement
    if (widget.userProfile.city != null && widget.userProfile.country != null) {
      achievements.add({
        'title': 'Cidadão do Mundo',
        'description': 'Informações de localização completas',
        'icon': Icons.public,
        'color': const Color(0xFF2196F3),
        'isUnlocked': true,
        'rarity': 'uncommon',
      });
    }

    // Age verification achievement
    if (widget.userProfile.birthDate != null) {
      achievements.add({
        'title': 'Verificado',
        'description': 'Data de nascimento confirmada',
        'icon': Icons.verified,
        'color': AppTheme.accentColor,
        'isUnlocked': true,
        'rarity': 'uncommon',
      });
    }

    // Add some locked achievements for motivation
    achievements.addAll([
      {
        'title': 'Veterano',
        'description': 'Complete 50 jogos',
        'icon': Icons.military_tech,
        'color': AppTheme.secondaryText,
        'isUnlocked': false,
        'rarity': 'legendary',
      },
      {
        'title': 'Estrela',
        'description': 'Receba 100 avaliações positivas',
        'icon': Icons.star,
        'color': AppTheme.secondaryText,
        'isUnlocked': false,
        'rarity': 'legendary',
      },
    ]);

    return achievements;
  }

  int _getProfileCompletionPercentage() {
    int completed = 0;
    const total = 7;

    if (widget.userProfile.name.isNotEmpty) completed++;
    if (widget.userProfile.gender != null) completed++;
    if (widget.userProfile.city != null) completed++;
    if (widget.userProfile.birthDate != null) completed++;
    if (widget.userProfile.club != null) completed++;
    if (widget.userProfile.nationality != null) completed++;
    if (widget.userProfile.country != null) completed++;

    return ((completed / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(24),
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
            _buildHeader(),
            const SizedBox(height: 24),
            _buildProgressCard(),
            const SizedBox(height: 24),
            _buildAchievementsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700),
                const Color(0xFFFFA500),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events,
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
                'Conquistas',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Badges e marcos alcançados',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final completionPercentage = _getProfileCompletionPercentage();
    final achievements = _getAchievements();
    final unlockedCount = achievements.where((a) => a['isUnlocked'] as bool).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentColor.withOpacity(0.1),
            AppTheme.successColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progresso do Perfil',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$unlockedCount/${achievements.length} conquistas desbloqueadas',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completionPercentage%',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.secondaryText.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completionPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accentColor, AppTheme.successColor],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid() {
    final achievements = _getAchievements();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return Transform.scale(
              scale: index < _badgeAnimations.length 
                  ? _badgeAnimations[index].value 
                  : 1.0,
              child: _buildAchievementBadge(
                achievement['title'] as String,
                achievement['description'] as String,
                achievement['icon'] as IconData,
                achievement['color'] as Color,
                achievement['isUnlocked'] as bool,
                achievement['rarity'] as String,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAchievementBadge(
    String title,
    String description,
    IconData icon,
    Color color,
    bool isUnlocked,
    String rarity,
  ) {
    return GestureDetector(
      onTap: () => _showAchievementDetail(title, description, icon, color, isUnlocked, rarity),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked 
              ? AppTheme.primaryBackground.withOpacity(0.5)
              : AppTheme.primaryBackground.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked 
                ? color.withOpacity(0.5)
                : AppTheme.secondaryText.withOpacity(0.2),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? color.withOpacity(0.2)
                    : AppTheme.secondaryText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isUnlocked ? color : AppTheme.secondaryText.withOpacity(0.5),
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? AppTheme.primaryText : AppTheme.secondaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRarityColor(rarity).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getRarityLabel(rarity),
                style: AppTheme.bodyMedium.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? _getRarityColor(rarity) : AppTheme.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(
    String title,
    String description,
    IconData icon,
    Color color,
    bool isUnlocked,
    String rarity,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? color.withOpacity(0.2)
                      : AppTheme.secondaryText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: isUnlocked ? color : AppTheme.secondaryText,
                    width: 3,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isUnlocked ? color : AppTheme.secondaryText,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRarityColor(rarity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRarityLabel(rarity),
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getRarityColor(rarity),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    isUnlocked ? Icons.check_circle : Icons.lock,
                    color: isUnlocked ? AppTheme.successColor : AppTheme.secondaryText,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUnlocked ? 'Desbloqueado' : 'Bloqueado',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? AppTheme.successColor : AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return const Color(0xFF9E9E9E);
      case 'uncommon':
        return const Color(0xFF4CAF50);
      case 'rare':
        return const Color(0xFF2196F3);
      case 'epic':
        return const Color(0xFF9C27B0);
      case 'legendary':
        return const Color(0xFFFFD700);
      default:
        return AppTheme.secondaryText;
    }
  }

  String _getRarityLabel(String rarity) {
    switch (rarity) {
      case 'common':
        return 'COMUM';
      case 'uncommon':
        return 'INCOMUM';
      case 'rare':
        return 'RARO';
      case 'epic':
        return 'ÉPICO';
      case 'legendary':
        return 'LENDÁRIO';
      default:
        return 'COMUM';
    }
  }
}
