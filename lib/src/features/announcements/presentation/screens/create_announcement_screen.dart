import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/announcement_controller.dart';
import '../../data/models/announcement.dart';
import '../../../user_profile/data/models/user_profile.dart';
import '../../../goalkeeper_search/data/services/goalkeeper_search_service.dart';
import '../../../../shared/services/location_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stadiumController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  
  // Goalkeeper hiring fields
  bool _needsGoalkeeper = false;
  String? _selectedGoalkeeperId;
  final List<UserProfile> _availableGoalkeepers = [];
  final TextEditingController _goalkeeperSearchController = TextEditingController();
  List<UserProfile> _filteredGoalkeepers = [];
  bool _isLoadingGoalkeepers = false;
  Position? _userLocation;
  final GoalkeeperSearchService _goalkeeperSearchService = GoalkeeperSearchService();
  final LocationService _locationService = LocationService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stadiumController.dispose();
    _goalkeeperSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _goalkeeperSearchController.addListener(_filterGoalkeepers);
  }

  // Get user's current location
  Future<void> _getUserLocation() async {
    try {
      _userLocation = await _locationService.getCurrentLocation();
      if (_userLocation != null) {
        await _fetchNearbyGoalkeepers();
      } else {
        _showErrorSnackBar('Não foi possível obter sua localização');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao obter localização: ${e.toString()}');
    }
  }

  // Fetch nearby goalkeepers from database
  Future<void> _fetchNearbyGoalkeepers() async {
    setState(() {
      _isLoadingGoalkeepers = true;
    });

    try {
      // Get current user info to use city as fallback
      final currentUser = Supabase.instance.client.auth.currentUser;
      String? userCity;
      
      if (currentUser != null) {
        try {
          final userResponse = await Supabase.instance.client
              .from('users')
              .select('city')
              .eq('id', currentUser.id)
              .single();
          userCity = userResponse['city'];
        } catch (e) {
          print('Could not get user city: $e');
        }
      }

      final goalkeepers = await _goalkeeperSearchService.getNearbyGoalkeepers(
        radiusKm: 50.0,
        userLocation: _userLocation,
        userCity: userCity,
      );

      setState(() {
        _availableGoalkeepers.clear();
        _availableGoalkeepers.addAll(goalkeepers);
        _filteredGoalkeepers = List.from(_availableGoalkeepers);
        _isLoadingGoalkeepers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGoalkeepers = false;
      });
      _showErrorSnackBar('Erro ao carregar guarda-redes: ${e.toString()}');
    }
  }

  // Filter goalkeepers based on search input
  void _filterGoalkeepers() {
    final query = _goalkeeperSearchController.text.toLowerCase();
    setState(() {
      _filteredGoalkeepers = _availableGoalkeepers
          .where((goalkeeper) => 
              goalkeeper.name.toLowerCase().contains(query))
          .toList();
    });
  }

  // Handle goalkeeper hiring checkbox change
  void _onGoalkeeperHiringChanged(bool? value) async {
    setState(() {
      _needsGoalkeeper = value ?? false;
      if (!_needsGoalkeeper) {
        _selectedGoalkeeperId = null;
        _goalkeeperSearchController.clear();
      }
    });

    if (_needsGoalkeeper && _userLocation == null) {
      await _getUserLocation();
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2C2C2C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2C2C2C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showErrorSnackBar('Por favor, selecione uma data');
      return;
    }

    if (_selectedTime == null) {
      _showErrorSnackBar('Por favor, selecione uma hora');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final announcement = Announcement(
        id: 0, // Will be set by database
        createdBy: currentUser.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        date: _selectedDate!,
        time: _selectedTime!,
        price: _priceController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_priceController.text.trim()),
        stadium: _stadiumController.text.trim().isEmpty 
            ? null 
            : _stadiumController.text.trim(),
        createdAt: DateTime.now(),
      );

      final controller = Provider.of<AnnouncementController>(context, listen: false);
      await controller.createAnnouncement(announcement);

      if (mounted) {
        _showSuccessSnackBar('Anúncio criado com sucesso!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Falha ao criar anúncio: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Criar Anúncio',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              _buildInputField(
                controller: _titleController,
                label: 'Título',
                hint: 'Digite o título do anúncio',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Título é obrigatório';
                  }
                  if (value.trim().length < 3) {
                    return 'Título deve ter pelo menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              _buildInputField(
                controller: _descriptionController,
                label: 'Descrição',
                hint: 'Digite a descrição do anúncio (opcional)',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Date and Time Row
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeField(
                      label: 'Data',
                      value: _selectedDate != null ? _formatDate(_selectedDate!) : null,
                      hint: 'Selecionar data',
                      onTap: _selectDate,
                      validator: () => _selectedDate == null ? 'Data é obrigatória' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateTimeField(
                      label: 'Hora',
                      value: _selectedTime != null ? _formatTime(_selectedTime!) : null,
                      hint: 'Selecionar hora',
                      onTap: _selectTime,
                      validator: () => _selectedTime == null ? 'Hora é obrigatória' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price Field
              _buildInputField(
                controller: _priceController,
                label: 'Preço',
                hint: 'Digite o preço (opcional)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final price = double.tryParse(value.trim());
                    if (price == null || price < 0) {
                      return 'Por favor, digite um preço válido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stadium Field
              _buildInputField(
                controller: _stadiumController,
                label: 'Estádio',
                hint: 'Digite o nome do estádio (opcional)',
              ),
              const SizedBox(height: 24),

              // Goalkeeper Hiring Section
              _buildGoalkeeperSection(),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: const Color(0xFF757575),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Criar Anúncio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 14,
            ),
          ),
          style: const TextStyle(
            color: Color(0xFF2C2C2C),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
    required String? Function() validator,
  }) {
    final hasError = validator() != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? const Color(0xFFFF6B6B) : const Color(0xFFE0E0E0),
                width: hasError ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? hint,
                  style: TextStyle(
                    color: value != null ? const Color(0xFF2C2C2C) : const Color(0xFF757575),
                    fontSize: 16,
                  ),
                ),
                Icon(
                  label == 'Date' ? Icons.calendar_today : Icons.access_time,
                  color: const Color(0xFF757575),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            validator()!,
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGoalkeeperSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Goalkeeper hiring checkbox
        Row(
          children: [
            Checkbox(
              value: _needsGoalkeeper,
              onChanged: _onGoalkeeperHiringChanged,
              activeColor: const Color(0xFF4CAF50),
            ),
            const Expanded(
              child: Text(
                'Contratar guarda-redes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ),
          ],
        ),
        
        // Goalkeeper dropdown (shown when checkbox is checked)
        if (_needsGoalkeeper) ...[
          const SizedBox(height: 16),
          const Text(
            'Selecionar guarda-redes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          
          // Search field for goalkeepers
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              children: [
                // Search input
                TextFormField(
                  controller: _goalkeeperSearchController,
                  decoration: const InputDecoration(
                    hintText: 'Digite para pesquisar guarda-redes...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF757575)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    hintStyle: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 14,
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF2C2C2C),
                    fontSize: 16,
                  ),
                ),
                
                // Goalkeeper list
                if (_isLoadingGoalkeepers)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                  )
                else if (_filteredGoalkeepers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nenhum guarda-redes encontrado na sua área',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filteredGoalkeepers.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: Color(0xFFE0E0E0),
                      ),
                      itemBuilder: (context, index) {
                        final goalkeeper = _filteredGoalkeepers[index];
                        final isSelected = _selectedGoalkeeperId == goalkeeper.id;
                        
                        return ListTile(
                          onTap: () {
                            setState(() {
                              _selectedGoalkeeperId = goalkeeper.id;
                            });
                          },
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF4CAF50),
                            child: Text(
                              goalkeeper.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            goalkeeper.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          subtitle: Text(
                            _getGoalkeeperDistance(goalkeeper),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4CAF50),
                                )
                              : const Icon(
                                  Icons.radio_button_unchecked,
                                  color: Color(0xFF757575),
                                ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getGoalkeeperDistance(UserProfile goalkeeper) {
    // Show distance if both user and goalkeeper have location data
    if (_userLocation != null && goalkeeper.hasLocation) {
      final distance = _locationService.calculateDistance(
        _userLocation!.latitude,
        _userLocation!.longitude,
        goalkeeper.latitude!,
        goalkeeper.longitude!,
      );
      return '${distance.toStringAsFixed(1)} km de distância';
    }
    
    // Fallback to city or rating info
    if (goalkeeper.city != null && goalkeeper.city!.isNotEmpty) {
      return goalkeeper.city!;
    }
    
    final rating = goalkeeper.getOverallRating();
    if (rating > 0) {
      return 'Avaliação: ${rating.toStringAsFixed(1)}/5';
    }
    
    return 'Guarda-redes disponível';
  }
}
