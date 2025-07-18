import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/announcement_controller.dart';
import '../../data/models/announcement.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stadiumController.dispose();
    super.dispose();
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
      _showErrorSnackBar('Please select a date');
      return;
    }

    if (_selectedTime == null) {
      _showErrorSnackBar('Please select a time');
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
        _showSuccessSnackBar('Announcement created successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to create announcement: ${e.toString()}');
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
          'Create Announcement',
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
                label: 'Title',
                hint: 'Enter announcement title',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              _buildInputField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter announcement description (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Date and Time Row
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeField(
                      label: 'Date',
                      value: _selectedDate != null ? _formatDate(_selectedDate!) : null,
                      hint: 'Select date',
                      onTap: _selectDate,
                      validator: () => _selectedDate == null ? 'Date is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateTimeField(
                      label: 'Time',
                      value: _selectedTime != null ? _formatTime(_selectedTime!) : null,
                      hint: 'Select time',
                      onTap: _selectTime,
                      validator: () => _selectedTime == null ? 'Time is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price Field
              _buildInputField(
                controller: _priceController,
                label: 'Price',
                hint: 'Enter price (optional)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final price = double.tryParse(value.trim());
                    if (price == null || price < 0) {
                      return 'Please enter a valid price';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stadium Field
              _buildInputField(
                controller: _stadiumController,
                label: 'Stadium',
                hint: 'Enter stadium name (optional)',
              ),
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
                          'Create Announcement',
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
}