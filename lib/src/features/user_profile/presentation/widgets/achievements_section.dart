import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/user_profile/data/models/achievement.dart';
import 'package:goalkeeper/src/features/user_profile/data/models/user_profile.dart';
import 'package:goalkeeper/src/features/user_profile/data/services/achievement_service.dart';
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
  late final AchievementService _achievementService;
  late List<Achievement> _achievements;

  @override
  void initState() {
    super.initState();
    _achievementService = AchievementService();
    _achievements = _achievementService.getAchievements(widget.userProfile);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _badgeAnimations = List.generate(
      _achievements.length,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF45A049),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final completionPercentage = _achievementService.getProfileCompletionPercentage(widget.userProfile);

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
                      '$unlockedCount/${_achievements.length} conquistas desbloqueadas',
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
          itemCount: _achievements.length,
          itemBuilder: (context, index) {
            final achievement = _achievements[index];
            return Transform.scale(
              scale: index < _badgeAnimations.length
                  ? _badgeAnimations[index].value
                  : 1.0,
              child: _buildAchievementBadge(
                achievement.title,
                achievement.description,
                achievement.icon,
                achievement.color,
                achievement.isUnlocked,
                achievement.rarity,
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
    AchievementRarity rarity,
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
            Expanded(
              child: Text(
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
    AchievementRarity rarity,
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

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF9E9E9E);
      case AchievementRarity.uncommon:
        return const Color(0xFF4CAF50);
      case AchievementRarity.rare:
        return const Color(0xFF2196F3);
      case AchievementRarity.epic:
        return const Color(0xFF9C27B0);
      case AchievementRarity.legendary:
        return const Color(0xFFFFD700);
      default:
        return AppTheme.secondaryText;
    }
  }

  String _getRarityLabel(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'COMUM';
      case AchievementRarity.uncommon:
        return 'INCOMUM';
      case AchievementRarity.rare:
        return 'RARO';
      case AchievementRarity.epic:
        return 'ÉPICO';
      case AchievementRarity.legendary:
        return 'LENDÁRIO';
      default:
        return 'COMUM';
    }
  }
}
