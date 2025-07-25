import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/user_profile/data/models/achievement.dart';
import 'package:goalkeeper/src/features/user_profile/data/models/user_profile.dart';
import 'package:goalkeeper/src/features/auth/presentation/theme/app_theme.dart';

class AchievementService {
  // In a real app, this would come from a database or a config file.
  final List<Achievement> _allAchievements = [
    Achievement(
      id: 'profile_complete',
      title: 'Perfil Completo',
      description: 'Completou todas as informações do perfil',
      icon: Icons.account_circle,
      color: AppTheme.successColor,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'goalkeeper',
      title: 'Guardião',
      description: 'Registado como guarda-redes',
      icon: Icons.sports_soccer,
      color: AppTheme.accentColor,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'professional',
      title: 'Profissional',
      description: 'Definiu preço por jogo',
      icon: Icons.euro,
      color: const Color(0xFFFFD700),
      rarity: AchievementRarity.epic,
    ),
    Achievement(
      id: 'club_member',
      title: 'Membro de Clube',
      description: 'Associado a um clube',
      icon: Icons.groups,
      color: AppTheme.successColor,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'world_citizen',
      title: 'Cidadão do Mundo',
      description: 'Informações de localização completas',
      icon: Icons.public,
      color: const Color(0xFF2196F3),
      rarity: AchievementRarity.uncommon,
    ),
    Achievement(
      id: 'verified',
      title: 'Verificado',
      description: 'Data de nascimento confirmada',
      icon: Icons.verified,
      color: AppTheme.accentColor,
      rarity: AchievementRarity.uncommon,
    ),
    Achievement(
      id: 'veteran',
      title: 'Veterano',
      description: 'Conta com mais de 6 meses',
      icon: Icons.military_tech,
      color: AppTheme.secondaryText,
      rarity: AchievementRarity.legendary,
    ),
    Achievement(
      id: 'star',
      title: 'Estrela',
      description: 'Avaliação geral superior a 80',
      icon: Icons.star,
      color: AppTheme.secondaryText,
      rarity: AchievementRarity.legendary,
    ),
  ];

  List<Achievement> getAchievements(UserProfile userProfile) {
    return _allAchievements.map((achievement) {
      bool isUnlocked = _isAchievementUnlocked(achievement.id, userProfile);
      return Achievement(
        id: achievement.id,
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon,
        color: isUnlocked ? achievement.color : AppTheme.secondaryText,
        rarity: achievement.rarity,
        isUnlocked: isUnlocked,
      );
    }).toList();
  }

  bool _isAchievementUnlocked(String achievementId, UserProfile userProfile) {
    switch (achievementId) {
      case 'profile_complete':
        return getProfileCompletionPercentage(userProfile) >= 100;
      case 'goalkeeper':
        return userProfile.isGoalkeeper;
      case 'professional':
        return userProfile.isGoalkeeper && userProfile.pricePerGame != null;
      case 'club_member':
        return userProfile.club != null && userProfile.club!.isNotEmpty;
      case 'world_citizen':
        return userProfile.city != null && userProfile.country != null;
      case 'verified':
        return userProfile.birthDate != null;
      case 'veteran':
        return DateTime.now().difference(userProfile.createdAt).inDays >= 180;
      case 'star':
        return userProfile.getOverallRating() >= 80;
      default:
        return false;
    }
  }

  int getProfileCompletionPercentage(UserProfile userProfile) {
    int completed = 0;
    const total = 7;

    if (userProfile.name.isNotEmpty) completed++;
    if (userProfile.gender != null) completed++;
    if (userProfile.city != null) completed++;
    if (userProfile.birthDate != null) completed++;
    if (userProfile.club != null) completed++;
    if (userProfile.nationality != null) completed++;
    if (userProfile.country != null) completed++;

    return ((completed / total) * 100).round();
  }
}
