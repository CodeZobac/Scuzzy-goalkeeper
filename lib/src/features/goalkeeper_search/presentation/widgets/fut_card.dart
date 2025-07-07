import 'package:flutter/material.dart';
import '../../data/models/goalkeeper.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import 'fifa_card_clipper.dart';

enum CardRarity { Bronze, Silver, Gold, Special }

class FutCarde extends StatelessWidget {
  final Goalkeeper goalkeeper;

  const FutCarde({super.key, required this.goalkeeper});

  CardRarity get _rarity {
    final rating = goalkeeper.overallRating ?? 0;
    if (rating >= 85) return CardRarity.Special;
    if (rating >= 75) return CardRarity.Gold;
    if (rating >= 65) return CardRarity.Silver;
    return CardRarity.Bronze;
  }

  List<Color> get _rarityGradientColors {
    switch (_rarity) {
      case CardRarity.Special:
        return [
          Colors.blue.shade800,
          Colors.blue.shade600,
          Colors.blue.shade400,
          Colors.blue.shade600,
          Colors.blue.shade800,
        ];
      case CardRarity.Gold:
        return [
          Colors.amber.shade700,
          Colors.amber.shade500,
          Colors.amber.shade300,
          Colors.amber.shade500,
          Colors.amber.shade700,
        ];
      case CardRarity.Silver:
        return [
          Colors.grey.shade500,
          Colors.grey.shade400,
          Colors.grey.shade300,
          Colors.grey.shade400,
          Colors.grey.shade500,
        ];
      case CardRarity.Bronze:
        return [
          const Color(0xFFCD7F32),
          const Color(0xFFB87333),
          const Color(0xFF8C7853),
          const Color(0xFFB87333),
          const Color(0xFFCD7F32),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: FifaCardClipper(),
      child: Card(
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            gradient: LinearGradient(
              colors: _rarityGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              _buildPlayerImage(),
              _buildCardDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerImage() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: CircleAvatar(
          radius: 50,
          backgroundImage: goalkeeper.photoUrl != null
              ? NetworkImage(goalkeeper.photoUrl!)
              : null,
          child: goalkeeper.photoUrl == null
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
      ),
    );
  }

  Widget _buildCardDetails() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24.0),
            bottomRight: Radius.circular(24.0),
          ),
        ),
        child: Column(
          children: [
            Text(
              goalkeeper.name,
              style: AppTheme.headingMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Rating', goalkeeper.overallRating?.toString() ?? 'N/A'),
                _buildStatColumn('Value', goalkeeper.displayPrice),
                _buildStatColumn('Position', 'GK'),
              ],
            ),
            if (goalkeeper.inDemand == true)
              Container(
                margin: const EdgeInsets.only(top: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'In Demand',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: AppTheme.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
