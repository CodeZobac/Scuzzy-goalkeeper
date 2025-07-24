import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_profile.dart';
import '../controllers/user_profile_controller.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/primary_button.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> with TickerProviderStateMixin {
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
  
  String? _selectedGender = 'Masculino';
  bool _isMasculino = true;
  
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController();
    _genderController = TextEditingController(text: 'Masculino');
    _cityController = TextEditingController();
    _birthDateController = TextEditingController();
    _clubController = TextEditingController();
    _nationalityController = TextEditingController();
    _countryController = TextEditingController();
    _priceController = TextEditingController();
    
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
      _startAnimations();
    });
  }
  
  void _startAnimations() async {
    _mainAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _cardAnimationController.forward();
  }

  Future<void> _loadUserProfile() async {
    final controller = Provider.of<UserProfileController>(context, listen: false);
    final profile = await controller.userProfile;
    if (profile != null) {
      setState(() {
        _userProfile = profile;
        _nameController.text = profile.name;
        _genderController.text = profile.gender ?? '';
        _cityController.text = profile.city ?? '';
        _birthDateController.text = profile.birthDate != null 
            ? _formatDateForDisplay(profile.birthDate!)
            : '';
        _clubController.text = profile.club ?? '';
        _nationalityController.text = profile.nationality ?? '';
        _countryController.text = profile.country ?? '';
        _priceController.text = profile.pricePerGame?.toString() ?? '';
        _isGoalkeeper = profile.isGoalkeeper;
        _selectedDate = profile.birthDate;
        _selectedGender = profile.gender ?? 'Masculino';
        _genderController.text = _selectedGender!;
        if (_selectedGender == 'Feminino') {
          _isMasculino = false;
        } else {
          _isMasculino = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<UserProfileController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFF4CAF50),
            ],
          ),
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
          const SizedBox(width: 16),
          Text(
            'Complete o seu Perfil',
            style: AppTheme.headingMedium.copyWith(color: const Color(0xFF000000)),
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
                          color: const Color(0xFF1B5E20).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            _userProfile?.name.isNotEmpty == true
                                ? _userProfile!.name[0].toUpperCase()
                                : 'U',
                            style: AppTheme.headingLarge.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF000000),
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
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFF1B5E20),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Color(0xFF1B5E20),
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
                    color: Colors.grey[600],
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
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF4CAF50).withOpacity(0.8),
              hintStyle: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 16,
              ),
              prefixIconColor: const Color(0xFF000000),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: const BorderSide(
                  color: Color(0xFF1B5E20),
                  width: 2,
                ),
              ),
            ),
          ),
          child: CustomTextField(
            floatingLabelBehavior: FloatingLabelBehavior.never,
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
        ),
        const SizedBox(height: AppTheme.spacing),
        _buildGenderSwitch(),
        const SizedBox(height: AppTheme.spacing),
        _buildDateField(),
        const SizedBox(height: AppTheme.spacing),
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF4CAF50).withOpacity(0.8),
              hintStyle: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 16,
              ),
              prefixIconColor: const Color(0xFF000000),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: const BorderSide(
                  color: Color(0xFF1B5E20),
                  width: 2,
                ),
              ),
            ),
          ),
          child: CustomTextField(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            hintText: 'Digite sua nacionalidade',
            labelText: 'Nacionalidade',
            prefixIcon: Icons.flag_outlined,
            controller: _nationalityController,
          ),
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
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF4CAF50).withOpacity(0.8),
              hintStyle: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 16,
              ),
              prefixIconColor: const Color(0xFF000000),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: const BorderSide(
                  color: Color(0xFF1B5E20),
                  width: 2,
                ),
              ),
            ),
          ),
          child: CustomTextField(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            hintText: 'Digite o nome do seu clube',
            labelText: 'Clube',
            prefixIcon: Icons.groups_outlined,
            controller: _clubController,
          ),
        ),
        if (_isGoalkeeper) ...[
          const SizedBox(height: AppTheme.spacing),
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF4CAF50).withOpacity(0.8),
                hintStyle: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
                labelStyle: const TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 16,
                ),
                prefixIconColor: const Color(0xFF000000),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: const BorderSide(
                    color: Color(0xFF1B5E20),
                    width: 2,
                  ),
                ),
              ),
            ),
            child: CustomTextField(
              floatingLabelBehavior: FloatingLabelBehavior.never,
              hintText: 'Digite o preço por jogo (€)',
              labelText: 'Preço por Jogo',
              prefixIcon: Icons.euro_outlined,
              controller: _priceController,
              keyboardType: TextInputType.number,
            ),
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
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF4CAF50).withOpacity(0.8),
              hintStyle: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 16,
              ),
              prefixIconColor: const Color(0xFF000000),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: const BorderSide(
                  color: Color(0xFF1B5E20),
                  width: 2,
                ),
              ),
            ),
          ),
          child: CustomTextField(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            hintText: 'Digite sua cidade',
            labelText: 'Cidade',
            prefixIcon: Icons.location_city_outlined,
            controller: _cityController,
          ),
        ),
        const SizedBox(height: AppTheme.spacing),
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF4CAF50).withOpacity(0.8),
              hintStyle: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 16,
              ),
              prefixIconColor: const Color(0xFF000000),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: const BorderSide(
                  color: Color(0xFF1B5E20),
                  width: 2,
                ),
              ),
            ),
          ),
          child: CustomTextField(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            hintText: 'Digite seu país',
            labelText: 'País',
            prefixIcon: Icons.public_outlined,
            controller: _countryController,
          ),
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
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.05),
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
                            color: const Color(0xFF000000),
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
  
  Widget _buildGenderSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[600]!.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Feminino',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: !_isMasculino ? AppTheme.authPrimaryGreen : const Color(0xFF000000),
            ),
          ),
          Switch(
            value: _isMasculino,
            onChanged: (value) {
              setState(() {
                _isMasculino = value;
                _selectedGender = _isMasculino ? 'Masculino' : 'Feminino';
                _genderController.text = _selectedGender!;
              });
            },
            activeTrackColor: AppTheme.authPrimaryGreen.withOpacity(0.5),
            activeColor: AppTheme.authPrimaryGreen,
            inactiveTrackColor: AppTheme.authSecondaryGreen.withOpacity(0.5),
            inactiveThumbColor: AppTheme.authSecondaryGreen,
          ),
          Text(
            'Masculino',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: _isMasculino ? AppTheme.authPrimaryGreen : const Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: AbsorbPointer(
        child: Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF4CAF50).withOpacity(0.8),
              hintStyle: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 16,
              ),
              prefixIconColor: const Color(0xFF000000),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: const BorderSide(
                  color: Color(0xFF1B5E20),
                  width: 2,
                ),
              ),
            ),
          ),
          child: CustomTextField(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            hintText: 'Selecione sua data de nascimento',
            labelText: 'Data de Nascimento',
            prefixIcon: Icons.calendar_today_outlined,
            controller: _birthDateController,
          ),
        ),
      ),
    );
  }
  
  Widget _buildGoalkeeperSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isGoalkeeper ? Colors.purple : Colors.grey[600]!.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer,
            color: _isGoalkeeper ? Colors.purple : Colors.grey[600],
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
                    color: _isGoalkeeper ? Colors.purple : const Color(0xFF000000),
                  ),
                ),
                Text(
                  'Ative se você é um guarda-redes',
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 12,
                    color: Colors.grey[600],
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
            activeColor: Colors.purple,
            inactiveTrackColor: Colors.grey[600]!.withOpacity(0.3),
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
            text: _isLoading ? 'Salvando...' : 'Salvar Perfil',
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B5E20),
              onPrimary: Colors.white,
              surface: Color(0xFF4CAF50),
              onSurface: Color(0xFF000000),
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
        id: _userProfile!.id,
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
        profileCompleted: true,
      );
      
      await controller.updateUserProfile(updatedProfile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil salvo com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar perfil. Tente novamente.'),
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
