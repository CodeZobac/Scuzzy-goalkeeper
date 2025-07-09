import 'package:flutter/material.dart';
import '../../features/auth/presentation/theme/app_theme.dart';
import '../../features/goalkeeper_search/presentation/screens/goalkeeper_search_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Home!',
            style: AppTheme.headingLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Find the perfect goalkeeper for your team',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              width: double.infinity,
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: 80,
                      color: AppTheme.accentColor.withOpacity(0.8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start your goalkeeper search',
                      style: AppTheme.headingMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discover talented goalkeepers in your area and build your dream team.',
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Busca',
            style: AppTheme.headingLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Encontre guarda-redes por localização, nível e mais',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalkeeperSearchScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBackground.withOpacity(0.8),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Procurar guarda-redes...',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.secondaryText,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _SearchFilterCard(
                  icon: Icons.location_on,
                  title: 'Localização',
                  subtitle: 'Por cidade',
                  onTap: () => _navigateToSearch(context),
                ),
                _SearchFilterCard(
                  icon: Icons.euro,
                  title: 'Preço',
                  subtitle: 'Por valor',
                  onTap: () => _navigateToSearch(context),
                ),
                _SearchFilterCard(
                  icon: Icons.sports_soccer,
                  title: 'Experiência',
                  subtitle: 'Por clube',
                  onTap: () => _navigateToSearch(context),
                ),
                _SearchFilterCard(
                  icon: Icons.person,
                  title: 'Perfil',
                  subtitle: 'Detalhado',
                  onTap: () => _navigateToSearch(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoalkeeperSearchScreen(),
      ),
    );
  }
}

class _SearchFilterCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SearchFilterCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TeamContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Team',
            style: AppTheme.headingLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your team and track performance',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _TeamMemberCard(
                  name: 'João Silva',
                  position: 'Goalkeeper',
                  rating: 4.8,
                  avatar: Icons.person,
                ),
                const SizedBox(height: 16),
                _TeamMemberCard(
                  name: 'Maria Santos',
                  position: 'Defender',
                  rating: 4.6,
                  avatar: Icons.person,
                ),
                const SizedBox(height: 16),
                _TeamMemberCard(
                  name: 'Pedro Costa',
                  position: 'Midfielder',
                  rating: 4.7,
                  avatar: Icons.person,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final String name;
  final String position;
  final double rating;
  final IconData avatar;

  const _TeamMemberCard({
    required this.name,
    required this.position,
    required this.rating,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.buttonGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              avatar,
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
                  name,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  position,
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(
                Icons.star,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                rating.toString(),
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MapContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MapScreen();
  }
}
