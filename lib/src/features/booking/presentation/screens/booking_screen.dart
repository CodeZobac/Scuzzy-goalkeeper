import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../goalkeeper_search/data/models/goalkeeper.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../auth/presentation/widgets/primary_button.dart';
import '../controllers/booking_controller.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/models/field.dart';

class BookingScreen extends StatefulWidget {
  final Goalkeeper goalkeeper;

  const BookingScreen({
    super.key,
    required this.goalkeeper,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BookingController(BookingRepository())..initialize(),
      child: Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Agendar Jogo',
                        style: AppTheme.headingLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Guarda-redes: ${widget.goalkeeper.name}',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _contentAnimationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Consumer<BookingController>(
              builder: (context, controller, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                  child: Column(
                    children: [
                      _buildGoalkeeperSummary(),
                      const SizedBox(height: AppTheme.spacingLarge),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildDateSelection(controller),
                              const SizedBox(height: AppTheme.spacing),
                              if (controller.selectedDate != null) ...[
                                _buildTimeSlotSelection(controller),
                                const SizedBox(height: AppTheme.spacing),
                              ],
                              _buildFieldSelection(controller),
                              const SizedBox(height: AppTheme.spacingLarge),
                            ],
                          ),
                        ),
                      ),
                      _buildBookingButton(controller),
                      const SizedBox(height: AppTheme.spacingLarge),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalkeeperSummary() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.secondaryBackground.withOpacity(0.6),
            AppTheme.secondaryBackground.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
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
                  widget.goalkeeper.name,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.goalkeeper.displayLocation} • ${widget.goalkeeper.displayPrice}',
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection(BookingController controller) {
    return _buildSectionCard(
      title: 'Selecionar Data',
      icon: Icons.calendar_today,
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacing),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground.withOpacity(0.8),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () => _selectDate(controller),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.selectedDate != null
                          ? _formatDate(controller.selectedDate!)
                          : 'Escolher data',
                      style: AppTheme.bodyLarge.copyWith(
                        color: controller.selectedDate != null
                            ? AppTheme.primaryText
                            : AppTheme.secondaryText,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSelection(BookingController controller) {
    return _buildSectionCard(
      title: 'Horários Disponíveis',
      icon: Icons.access_time,
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacing),
          if (controller.isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            )
          else if (controller.availableTimeSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing),
              child: Text(
                'Nenhum horário disponível para esta data',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else
            _buildTimeSlotGrid(controller),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(BookingController controller) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: controller.availableTimeSlots.length,
      itemBuilder: (context, index) {
        final slot = controller.availableTimeSlots[index];
        final isSelected = controller.selectedTime == slot;
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: GestureDetector(
                onTap: () => controller.selectedTime = slot,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppTheme.buttonGradient
                        : LinearGradient(
                            colors: [
                              AppTheme.secondaryBackground.withOpacity(0.8),
                              AppTheme.secondaryBackground.withOpacity(0.6),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppTheme.accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.primaryText,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFieldSelection(BookingController controller) {
    return _buildSectionCard(
      title: 'Campo (Opcional)',
      icon: Icons.sports_soccer,
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacing),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground.withOpacity(0.8),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<Field>(
              hint: Text(
                'Selecionar campo',
                style: AppTheme.bodyMedium,
              ),
              value: controller.selectedField,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              dropdownColor: AppTheme.secondaryBackground,
              style: AppTheme.bodyLarge,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.accentColor,
              ),
              items: [
                const DropdownMenuItem<Field>(
                  value: null,
                  child: Text('Sem campo específico'),
                ),
                ...controller.availableFields
                    .map((field) => DropdownMenuItem<Field>(
                          value: field,
                          child: Text(field.displayName),
                        ))
                    .toList(),
              ],
              onChanged: (field) => controller.selectedField = field,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildBookingButton(BookingController controller) {
    final canBook = controller.selectedTime != null && !controller.isLoading;
    
    return PrimaryButton(
      text: 'Confirmar Agendamento',
      icon: Icons.check,
      onPressed: canBook ? () => _confirmBooking(controller) : null,
      isLoading: controller.isLoading,
      width: double.infinity,
    );
  }

  Future<void> _selectDate(BookingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentColor,
              surface: AppTheme.secondaryBackground,
              background: AppTheme.primaryBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.selectedDate = picked;
      controller.selectedTime = null; // Reset time selection
      await controller.loadAvailableTimeSlots(widget.goalkeeper.id);
    }
  }

  Future<void> _confirmBooking(BookingController controller) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showError('Erro de autenticação. Faça login novamente.');
        return;
      }

      await controller.createBooking(user.id, widget.goalkeeper);
      
      if (controller.error != null) {
        _showError(controller.error!);
      } else {
        _showSuccess();
      }
    } catch (e) {
      _showError('Erro inesperado: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Agendamento criado com sucesso!'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day}/${date.month}/${date.year}';
  }
}
