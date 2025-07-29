import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/announcement.dart';
import '../controllers/announcement_controller.dart';
import '../../utils/error_handler.dart';
import '../../../goalkeeper_search/data/models/goalkeeper.dart';
import '../../../user_profile/data/models/user_profile.dart';

class AnnouncementForm extends StatefulWidget {
  const AnnouncementForm({super.key});

  @override
  State<AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<AnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stadiumController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  // Goalkeeper hiring fields
  bool _needsGoalkeeper = false;
  String? _selectedGoalkeeperId;
  final List<UserProfile> _availableGoalkeepers = [];
  final TextEditingController _goalkeeperController = TextEditingController();
  bool _isLoadingGoalkeepers = false;
  Position? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stadiumController.dispose();
    _priceController.dispose();
    _goalkeeperController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = position;
      });
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
    }
  }

  Future<void> _loadGoalkeepers() async {
    if (_userLocation == null) {
      AnnouncementErrorHandler.showErrorSnackBar(
        context,
        'Localização não disponível para encontrar guarda-redes próximos.',
      );
      return;
    }

    setState(() {
      _isLoadingGoalkeepers = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('user_profiles')
          .select()
          .eq('is_goalkeeper', true)
          .eq('profile_completed', true);

      final goalkeepers = (response as List)
          .map((json) => UserProfile.fromMap(json))
          .where((gk) => gk.city != null)
          .toList();

      // Filter goalkeepers within reasonable distance (e.g., 50km)
      // For now, we'll show all goalkeepers since we don't have exact coordinates
      setState(() {
        _availableGoalkeepers.clear();
        _availableGoalkeepers.addAll(goalkeepers);
      });
    } catch (e) {
      if (mounted) {
        AnnouncementErrorHandler.showErrorSnackBar(
          context,
          'Erro ao carregar guarda-redes: $e',
        );
      }
    } finally {
      setState(() {
        _isLoadingGoalkeepers = false;
      });
    }
  }

  Future<void> _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('pt', 'PT'),
      helpText: 'Selecionar Data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _presentTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Selecionar Hora',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        AnnouncementErrorHandler.showErrorSnackBar(
          context,
          'Por favor selecione uma data e hora.',
        );
        return;
      }

      final selectedGoalkeeper = _selectedGoalkeeperId != null 
          ? _availableGoalkeepers.firstWhere((gk) => gk.id == _selectedGoalkeeperId)
          : null;

      final announcement = Announcement(
        id: 0, // The database will generate the ID
        createdBy: Supabase.instance.client.auth.currentUser!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate!,
        time: _selectedTime!,
        price: double.tryParse(_priceController.text),
        stadium: _stadiumController.text,
        createdAt: DateTime.now(),
        needsGoalkeeper: _needsGoalkeeper,
        hiredGoalkeeperId: selectedGoalkeeper?.id,
        hiredGoalkeeperName: selectedGoalkeeper?.name,
        goalkeeperPrice: selectedGoalkeeper?.pricePerGame,
      );

      try {
        await Provider.of<AnnouncementController>(context, listen: false)
            .createAnnouncement(announcement);
        
        if (mounted) {
          AnnouncementErrorHandler.showSuccessSnackBar(
            context,
            'Anúncio criado com sucesso!',
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          AnnouncementErrorHandler.showErrorSnackBar(
            context,
            'Falha ao criar anúncio: ${AnnouncementErrorHandler.getErrorMessage(e)}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ex: Jogo amigável no estádio',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor insira um título.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Descreva os detalhes do jogo...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stadiumController,
              decoration: const InputDecoration(
                labelText: 'Estádio/Local',
                hintText: 'Nome do local onde será o jogo',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor insira o local do jogo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Preço (€)',
                hintText: 'Custo por pessoa (opcional)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            
            // Date Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Selecionar Data'
                          : 'Data: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: const Text('Escolher'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Time Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedTime == null
                          ? 'Selecionar Hora'
                          : 'Hora: ${_selectedTime!.format(context)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedTime == null ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _presentTimePicker,
                    child: const Text('Escolher'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Goalkeeper Hiring Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _needsGoalkeeper,
                        onChanged: (value) {
                          setState(() {
                            _needsGoalkeeper = value ?? false;
                            if (_needsGoalkeeper && _availableGoalkeepers.isEmpty) {
                              _loadGoalkeepers();
                            }
                          });
                        },
                        activeColor: const Color(0xFF4CAF50),
                      ),
                      const Expanded(
                        child: Text(
                          'Contratar guarda-redes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_needsGoalkeeper) ...[
                    const SizedBox(height: 16),
                    if (_isLoadingGoalkeepers)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_availableGoalkeepers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: const Text(
                          'Nenhum guarda-redes disponível na sua área.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedGoalkeeperId,
                        decoration: const InputDecoration(
                          labelText: 'Selecionar Guarda-redes',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableGoalkeepers.map((goalkeeper) {
                          return DropdownMenuItem<String>(
                            value: goalkeeper.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  goalkeeper.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${goalkeeper.city ?? 'Localização não definida'} • ${goalkeeper.pricePerGame != null ? '€${goalkeeper.pricePerGame!.toStringAsFixed(2)}/jogo' : 'Preço não definido'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGoalkeeperId = value;
                          });
                        },
                        isExpanded: true,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Submit Button
            Consumer<AnnouncementController>(
              builder: (context, controller, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isCreatingAnnouncement ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isCreatingAnnouncement
                        ? const SizedBox(
                            width: 20,
                            height: 20,
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
