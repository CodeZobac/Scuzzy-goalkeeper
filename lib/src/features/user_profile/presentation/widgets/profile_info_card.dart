import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/user_profile/data/models/user_profile.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class ProfileInfoCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final UserProfile userProfile;
  final bool isCareer;

  const ProfileInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.userProfile,
    this.isCareer = false,
  });

  @override
  State<ProfileInfoCard> createState() => _ProfileInfoCardState();
}

class _ProfileInfoCardState extends State<ProfileInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF45A049),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _toggleExpand,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildBasicInfo(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded ? _buildExpandedContent() : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
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
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            widget.title,
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.expand_more,
              color: AppTheme.accentColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    if (widget.isCareer) {
      return Column(
        children: [
          _buildInfoItem(
            Icons.groups_outlined,
            'Clube',
            widget.userProfile.club ?? 'Sem clube',
            isHighlighted: widget.userProfile.club != null,
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            widget.userProfile.isGoalkeeper ? Icons.sports_soccer : Icons.directions_run,
            'Posição',
            widget.userProfile.isGoalkeeper ? 'Guarda-Redes' : 'Jogador de Campo',
            isHighlighted: true,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildInfoItem(
            Icons.wc,
            'Género',
            widget.userProfile.gender ?? 'Não especificado',
            isHighlighted: widget.userProfile.gender != null,
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            Icons.location_city_outlined,
            'Cidade',
            widget.userProfile.city ?? 'Não especificada',
            isHighlighted: widget.userProfile.city != null,
          ),
        ],
      );
    }
  }

  Widget _buildExpandedContent() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
        ),
      ),
      child: widget.isCareer ? _buildCareerDetails() : _buildPersonalDetails(),
    );
  }

  Widget _buildPersonalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.accentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Detalhes Pessoais',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          Icons.cake_outlined,
          'Data de Nascimento',
          widget.userProfile.birthDate != null
              ? _formatDate(widget.userProfile.birthDate!)
              : 'Não especificada',
          widget.userProfile.birthDate != null,
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          Icons.flag_outlined,
          'Nacionalidade',
          widget.userProfile.nationality ?? 'Não especificada',
          widget.userProfile.nationality != null,
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          Icons.public_outlined,
          'País',
          widget.userProfile.country ?? 'Não especificado',
          widget.userProfile.country != null,
        ),
        if (widget.userProfile.birthDate != null) ...[
          const SizedBox(height: 16),
          _buildAgeCard(),
        ],
      ],
    );
  }

  Widget _buildCareerDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.sports_soccer,
              color: AppTheme.successColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Informações de Carreira',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.userProfile.isGoalkeeper && widget.userProfile.pricePerGame != null) ...[
          _buildDetailItem(
            Icons.euro_outlined,
            'Preço por Jogo',
            '€${widget.userProfile.pricePerGame!.toStringAsFixed(2)}',
            true,
          ),
          const SizedBox(height: 12),
        ],
        _buildDetailItem(
          Icons.location_on_outlined,
          'Localização',
          '${widget.userProfile.city ?? 'N/A'}, ${widget.userProfile.country ?? 'N/A'}',
          widget.userProfile.city != null || widget.userProfile.country != null,
        ),
        const SizedBox(height: 16),
        _buildExperienceCard(),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, bool isComplete) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isComplete 
                ? AppTheme.successColor.withOpacity(0.2)
                : AppTheme.secondaryText.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: isComplete ? AppTheme.successColor : AppTheme.secondaryText,
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isComplete ? AppTheme.primaryText : AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
        if (isComplete)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.check,
              color: AppTheme.successColor,
              size: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? AppTheme.accentColor.withOpacity(0.1)
            : AppTheme.primaryBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted 
              ? AppTheme.accentColor.withOpacity(0.3)
              : AppTheme.secondaryText.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted 
                  ? AppTheme.accentColor.withOpacity(0.2)
                  : AppTheme.secondaryText.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isHighlighted ? AppTheme.accentColor : AppTheme.secondaryText,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? AppTheme.primaryText : AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeCard() {
    final age = _calculateAge(widget.userProfile.birthDate!);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.1),
            AppTheme.successColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.access_time,
              color: AppTheme.accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Idade Atual',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$age anos',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard() {
    final experience = _getExperienceLevel();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.military_tech,
              color: AppTheme.successColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nível de Experiência',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  experience,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _getExperienceLevel() {
    // Calculate experience based on profile completion and other factors
    int score = 0;
    if (widget.userProfile.club != null) score += 25;
    if (widget.userProfile.pricePerGame != null) score += 25;
    if (widget.userProfile.birthDate != null) score += 25;
    if (widget.userProfile.nationality != null) score += 25;

    if (score >= 75) return 'Experiente';
    if (score >= 50) return 'Intermediário';
    if (score >= 25) return 'Iniciante';
    return 'Novo Jogador';
  }
}
