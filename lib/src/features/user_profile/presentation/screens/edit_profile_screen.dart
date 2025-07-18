import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_profile.dart';
import '../controllers/user_profile_controller.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _genderController;
  late final TextEditingController _cityController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _clubController;
  late final TextEditingController _nationalityController;
  late final TextEditingController _countryController;
  late final TextEditingController _priceController;

  late final AnimationController _mainAnimationController;
  late final AnimationController _cardAnimationController;
  late final AnimationController _saveButtonController;
  
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _cardStaggerAnimation;
  late final Animation<double> _saveButtonScaleAnimation;
  
  bool _isGoalkeeper = false;
  bool _isLoading = false;
  DateTime? _selectedDate;
  
  final List<String> _genderOptions = ['Masculino', 'Feminino', 'Outro'];
  String? _selectedGender;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController(text: widget.userProfile.name);
    _genderController = TextEditingController(text: widget.userProfile.gender);
    _cityController = TextEditingController(text: widget.userProfile.city);
    _birthDateController = TextEditingController(
        text: widget.userProfile.birthDate != null 
            ? _formatDateForDisplay(widget.userProfile.birthDate!)
            : '');
    _clubController = TextEditingController(text: widget.userProfile.club);
    _nationalityController = TextEditingController(text: widget.userProfile.nationality);
    _countryController = TextEditingController(text: widget.userProfile.country);
    _priceController = TextEditingController(
        text: widget.userProfile.pricePerGame?.toString() ?? '');
    
    // Initialize state
    _isGoalkeeper = widget.userProfile.isGoalkeeper;
    _selectedDate = widget.userProfile.birthDate;
    _selectedGender = widget.userProfile.gender;
    
    // Initialize animation controllers
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Setup animations
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _cardStaggerAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _saveButtonScaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _saveButtonController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });
  }
  
  void _startAnimations() async {
    _mainAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _cardAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<UserProfileController>(context);

    return Scaffold(
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingLarge),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProfileHeader(),
                            const SizedBox(height: AppTheme.spacingLarge),
                            _buildPersonalInfoCard(),
                            const SizedBox(height: AppTheme.spacing),
                            _buildSportsInfoCard(),
                            const SizedBox(height: AppTheme.spacing),
                            _buildLocationCard(),
                            const SizedBox(height: AppTheme.spacingLarge * 2),
                            _buildSaveButton(controller),
                            const SizedBox(height: AppTheme.spacingLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.primaryText,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.secondaryBackground.withOpacity(0.3),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Editar Perfil',
            style: AppTheme.headingMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    return AnimatedBuilder(
      animation: _cardStaggerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_cardStaggerAnimation.value * 0.2),
          child: Opacity(
            opacity: _cardStaggerAnimation.value,
            child: Column(
              children: [
                Hero(
                  tag: 'profile-avatar',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            widget.userProfile.name.isNotEmpty
                                ? widget.userProfile.name[0].toUpperCase()
                                : 'U',
                            style: AppTheme.headingLarge.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 5,
                          bottom: 5,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBackground,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: AppTheme.accentColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: AppTheme.accentColor,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Personalize seu perfil',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPersonalInfoCard() {
    return _buildAnimatedCard(
      'Informações Pessoais',
      Icons.person_outline,
      [
        CustomTextField(
          hintText: 'Digite seu nome completo',
          labelText: 'Nome',
          prefixIcon: Icons.person_outline,
          controller: _nameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nome é obrigatório';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing),
        _buildGenderDropdown(),
        const SizedBox(height: AppTheme.spacing),
        _buildDateField(),
        const SizedBox(height: AppTheme.spacing),
        CustomTextField(
          hintText: 'Digite sua nacionalidade',
          labelText: 'Nacionalidade',
          prefixIcon: Icons.flag_outlined,
          controller: _nationalityController,
        ),
      ],
    );
  }
  
  Widget _buildSportsInfoCard() {
    return _buildAnimatedCard(
      'Informações Desportivas',
      Icons.sports_soccer,
      [
        _buildGoalkeeperSwitch(),
        const SizedBox(height: AppTheme.spacing),
        CustomTextField(
          hintText: 'Digite o nome do seu clube',
          labelText: 'Clube',
          prefixIcon: Icons.groups_outlined,
          controller: _clubController,
        ),
        if (_isGoalkeeper) ...[
          const SizedBox(height: AppTheme.spacing),
          CustomTextField(
            hintText: 'Digite o preço por jogo (€)',
            labelText: 'Preço por Jogo',
            prefixIcon: Icons.euro_outlined,
            controller: _priceController,
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }
  
  Widget _buildLocationCard() {
    return _buildAnimatedCard(
      'Localização',
      Icons.location_on_outlined,
      [
        CustomTextField(
          hintText: 'Digite sua cidade',
          labelText: 'Cidade',
          prefixIcon: Icons.location_city_outlined,
          controller: _cityController,
        ),
        const SizedBox(height: AppTheme.spacing),
        CustomTextField(
          hintText: 'Digite seu país',
          labelText: 'País',
          prefixIcon: Icons.public_outlined,
          controller: _countryController,
        ),
      ],
    );
  }
  
  Widget _buildAnimatedCard(String title, IconData icon, List<Widget> children) {
    return AnimatedBuilder(
      animation: _cardStaggerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardStaggerAnimation.value)),
          child: Opacity(
            opacity: _cardStaggerAnimation.value,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.secondaryBackground,
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.buttonGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          title,
                          style: AppTheme.headingMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: AppTheme.secondaryText.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: const InputDecoration(
          labelText: 'Género',
          prefixIcon: Icon(Icons.wc, color: AppTheme.accentColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: AppTheme.secondaryBackground,
        style: AppTheme.bodyLarge,
        items: _genderOptions.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedGender = value;
            _genderController.text = value ?? '';
          });
        },
      ),
    );
  }
  
  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: AbsorbPointer(
        child: CustomTextField(
          hintText: 'Selecione sua data de nascimento',
          labelText: 'Data de Nascimento',
          prefixIcon: Icons.calendar_today_outlined,
          controller: _birthDateController,
        ),
      ),
    );
  }
  
  Widget _buildGoalkeeperSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isGoalkeeper ? AppTheme.successColor : AppTheme.secondaryText.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer,
            color: _isGoalkeeper ? AppTheme.successColor : AppTheme.secondaryText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sou Guarda-Redes',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isGoalkeeper ? AppTheme.successColor : AppTheme.primaryText,
                  ),
                ),
                Text(
                  'Ative se você é um guarda-redes',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isGoalkeeper,
            onChanged: (value) {
              setState(() {
                _isGoalkeeper = value;
              });
            },
            activeColor: AppTheme.successColor,
            inactiveTrackColor: AppTheme.secondaryText.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSaveButton(UserProfileController controller) {
    return AnimatedBuilder(
      animation: _saveButtonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _saveButtonScaleAnimation.value,
          child: PrimaryButton(
            text: _isLoading ? 'Salvando...' : 'Salvar Alterações',
            icon: Icons.save_outlined,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : () => _saveProfile(controller),
          ),
        );
      },
    );
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentColor,
              onPrimary: Colors.white,
              surface: AppTheme.secondaryBackground,
              onSurface: AppTheme.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = _formatDateForDisplay(picked);
      });
    }
  }
  
  Future<void> _saveProfile(UserProfileController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    _saveButtonController.forward().then((_) {
      _saveButtonController.reverse();
    });
    
    try {
      final updatedProfile = UserProfile(
        id: widget.userProfile.id,
        name: _nameController.text.trim(),
        gender: _selectedGender,
        city: _cityController.text.trim(),
        birthDate: _selectedDate,
        club: _clubController.text.trim(),
        nationality: _nationalityController.text.trim(),
        country: _countryController.text.trim(),
        isGoalkeeper: _isGoalkeeper,
        pricePerGame: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
      );
      
      await controller.updateUserProfile(updatedProfile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar perfil. Tente novamente.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  String _formatDateForDisplay(DateTime date) {
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genderController.dispose();
    _cityController.dispose();
    _birthDateController.dispose();
    _clubController.dispose();
    _nationalityController.dispose();
    _countryController.dispose();
    _priceController.dispose();
    _mainAnimationController.dispose();
    _cardAnimationController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }
}
