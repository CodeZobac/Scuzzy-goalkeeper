import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../auth/presentation/widgets/primary_button.dart';
import '../controllers/rating_controller.dart';
import '../widgets/stat_rating_widget.dart';
import '../widgets/star_rating_widget.dart';
import '../../../booking/data/models/booking.dart';
import '../../data/repositories/rating_repository.dart';

class RatingScreen extends StatefulWidget {
  final Booking booking;
  final String goalkeeperName;

  const RatingScreen({
    super.key,
    required this.booking,
    required this.goalkeeperName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _successAnimationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  bool _isDetailedReview = false;

  @override
  void initState() {
    super.initState();
    
    _headerAnimationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _contentAnimationController = AnimationController(
      duration: AppTheme.longAnimation,
      vsync: this,
    );
    
    _successAnimationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _startAnimations();
  }

  void _startAnimations() {
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    _successAnimationController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RatingController(RatingRepository()),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<RatingController>(
            builder: (context, controller, child) {
              return Column(
                children: [
                  _buildHeader(controller),
                  Expanded(
                    child: controller.hasSubmitted
                        ? _buildSuccessState(controller)
                        : _buildRatingForm(controller),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(RatingController controller) {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.hasSubmitted
                            ? 'Avaliação Enviada'
                            : 'Avaliar Guarda-redes',
                        style: AppTheme.headingLarge.copyWith(color: const Color(0xFF4CAF50)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.goalkeeperName,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.booking.displayDateTime,
                              style: AppTheme.bodyMedium.copyWith(color: Colors.black54),
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

  Widget _buildRatingForm(RatingController controller) {
    return AnimatedBuilder(
      animation: _contentAnimationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating Section
                  _buildRatingSection(controller),
                  const SizedBox(height: AppTheme.spacingLarge),
                  
                  // Comment Section
                  _buildCommentSection(controller),
                  
                  const SizedBox(height: AppTheme.spacingLarge),
                  
                  // Error Display
                  if (controller.error != null)
                    _buildErrorMessage(controller.error!),
                  
                  // Submit Button
                  _buildSubmitButton(controller),
                  const SizedBox(height: AppTheme.spacingLarge),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingSection(RatingController controller) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isDetailedReview)
            Center(
              child: StarRatingWidget(
                title: 'Como avalia o desempenho?',
                rating: ((controller.reflexes + controller.positioning + controller.distribution + controller.communication) / 4 / 20).round(),
                onRatingChanged: (rating) => controller.setOverallRating(rating),
                size: 45,
              ),
            ),
          const SizedBox(height: AppTheme.spacingLarge),
          if (_isDetailedReview)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como avalia o desempenho?',
                  style: AppTheme.headingMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                
                // Stat Rating Widgets
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatRatingWidget(
                      title: 'Reflexos',
                      rating: controller.reflexes,
                      onRatingChanged: (value) => controller.setStat('reflexes', value),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    StatRatingWidget(
                      title: 'Posicionamento',
                      rating: controller.positioning,
                      onRatingChanged: (value) => controller.setStat('positioning', value),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    StatRatingWidget(
                      title: 'Distribuição',
                      rating: controller.distribution,
                      onRatingChanged: (value) => controller.setStat('distribution', value),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    StatRatingWidget(
                      title: 'Comunicação',
                      rating: controller.communication,
                      onRatingChanged: (value) => controller.setStat('communication', value),
                    ),
                  ],
                ),
              ],
            ),
          if (!_isDetailedReview)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isDetailedReview = true;
                  });
                },
                child: Text(
                  'Deixar uma avaliação detalhada',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          if (_isDetailedReview)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isDetailedReview = false;
                  });
                },
                child: Text(
                  'Voltar',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentSection(RatingController controller) {
    return _isDetailedReview
        ? Container(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Comentário',
                      style: AppTheme.headingMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(opcional)',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing),
                Text(
                  'Partilhe a sua experiência com outros jogadores',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: AppTheme.spacing),
                TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  onChanged: controller.setComment,
                  maxLines: 4,
                  maxLength: 500,
                  style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        'O guarda-redes foi pontual, profissional e demonstrou excelente técnica...',
                    hintStyle: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(AppTheme.spacing),
                    counterStyle: AppTheme.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing),
      padding: const EdgeInsets.all(AppTheme.spacing),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(RatingController controller) {
    return PrimaryButton(
      text: 'Enviar Avaliação',
      onPressed: controller.canSubmit ? () => _submitRating(controller) : null,
      isLoading: controller.isLoading,
      icon: Icons.send,
    );
  }

  Widget _buildSuccessState(RatingController controller) {
    return AnimatedBuilder(
      animation: _successAnimationController,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.buttonGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    'Obrigado!',
                    style: AppTheme.headingLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing),
                  Text(
                    'A sua avaliação foi enviada com sucesso e irá ajudar outros jogadores.',
                    style: AppTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingLarge * 2),
                  PrimaryButton(
                    text: 'Voltar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icons.home,
                    width: 200,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitRating(RatingController controller) async {
    // Validate permissions
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Utilizador não autenticado')),
      );
      return;
    }

    if (!controller.validateRatingPermission(widget.booking, currentUser.id)) {
      return;
    }

    // Submit rating
    final success = await controller.submitRating(widget.booking);
    
    if (success) {
      _successAnimationController.forward();
    }
  }
}
