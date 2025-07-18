import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/user_profile/data/models/user_profile.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import 'dart:math' as math;

class StatsDashboard extends StatefulWidget {
  final UserProfile userProfile;

  const StatsDashboard({
    super.key,
    required this.userProfile,
  });

  @override
  State<StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<StatsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late List<Animation<double>> _progressAnimations;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimations = List.generate(
      _getStatsData().length,
      (index) => Tween<double>(
        begin: 0,
        end: _getStatsData()[index]['value'] as double,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Interval(
          index * 0.1,
          math.min(1.0, (index + 1) * 0.2),
          curve: Curves.easeOutCubic,
        ),
      )),
    );

    // Start animation after a delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getStatsData() {
    if (widget.userProfile.isGoalkeeper) {
      return [
        {
          'label': 'Reflexos',
          'value': 0.87,
          'color': AppTheme.successColor,
          'icon': Icons.sports_handball,
        },
        {
          'label': 'Posicionamento',
          'value': 0.84,
          'color': AppTheme.accentColor,
          'icon': Icons.gps_fixed,
        },
        {
          'label': 'Distribuição',
          'value': 0.79,
          'color': const Color(0xFF9C27B0),
          'icon': Icons.sports_soccer,
        },
        {
          'label': 'Comunicação',
          'value': 0.92,
          'color': const Color(0xFF2196F3),
          'icon': Icons.campaign,
        },
      ];
    } else {
      return [
        {
          'label': 'Velocidade',
          'value': 0.82,
          'color': AppTheme.successColor,
          'icon': Icons.speed,
        },
        {
          'label': 'Finalização',
          'value': 0.78,
          'color': AppTheme.accentColor,
          'icon': Icons.sports_soccer,
        },
        {
          'label': 'Passe',
          'value': 0.85,
          'color': const Color(0xFF9C27B0),
          'icon': Icons.sports_football,
        },
        {
          'label': 'Técnica',
          'value': 0.80,
          'color': const Color(0xFF2196F3),
          'icon': Icons.psychology,
        },
      ];
    }
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
            _buildStatsGrid(),
            const SizedBox(height: 20),
            _buildOverallPerformance(),
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
            gradient: AppTheme.buttonGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics_outlined,
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
                'Estatísticas de Performance',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.userProfile.isGoalkeeper
                    ? 'Habilidades de Guarda-Redes'
                    : 'Habilidades de Jogador',
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

  Widget _buildStatsGrid() {
    final stats = _getStatsData();
    
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildStatCard(
              stat['label'] as String,
              _progressAnimations[index].value,
              stat['value'] as double,
              stat['color'] as Color,
              stat['icon'] as IconData,
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    double animatedValue,
    double targetValue,
    Color color,
    IconData icon,
  ) {
    final percentage = (animatedValue * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const Spacer(),
              Text(
                '$percentage%',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: animatedValue,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallPerformance() {
    final stats = _getStatsData();
    final averageScore = stats.map((s) => s['value'] as double).reduce((a, b) => a + b) / stats.length;
    final overallPercentage = (averageScore * 100).round();
    
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
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 60,
            height: 60,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Stack(
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 6,
                      backgroundColor: AppTheme.secondaryText.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.secondaryText.withOpacity(0.2),
                      ),
                    ),
                    CircularProgressIndicator(
                      value: _progressController.value * averageScore,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        averageScore > 0.8 
                            ? AppTheme.successColor
                            : averageScore > 0.6
                                ? AppTheme.accentColor
                                : const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Geral',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$overallPercentage%',
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: averageScore > 0.8 
                            ? AppTheme.successColor
                            : averageScore > 0.6
                                ? AppTheme.accentColor
                                : const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPerformanceColor(averageScore).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPerformanceLabel(averageScore),
                        style: AppTheme.bodyMedium.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getPerformanceColor(averageScore),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Baseado nas suas habilidades técnicas',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double score) {
    if (score > 0.8) return AppTheme.successColor;
    if (score > 0.6) return AppTheme.accentColor;
    return const Color(0xFFFF9800);
  }

  String _getPerformanceLabel(double score) {
    if (score > 0.85) return 'EXCELENTE';
    if (score > 0.75) return 'MUITO BOM';
    if (score > 0.65) return 'BOM';
    if (score > 0.55) return 'MÉDIO';
    return 'EM DESENVOLVIMENTO';
  }
}
