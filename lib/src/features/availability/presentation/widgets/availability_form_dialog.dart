import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/auth/presentation/theme/app_theme.dart';
import 'package:goalkeeper/src/features/availability/data/models/availability.dart';

class AvailabilityFormDialog extends StatefulWidget {
  final Availability? availability;
  final Function(DateTime, String, String) onSave;

  const AvailabilityFormDialog({
    super.key,
    this.availability,
    required this.onSave,
  });

  @override
  State<AvailabilityFormDialog> createState() => _AvailabilityFormDialogState();
}

class _AvailabilityFormDialogState extends State<AvailabilityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDay;
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.availability != null) {
      _selectedDay = widget.availability!.day;
      _startTimeController.text = widget.availability!.startTime;
      _endTimeController.text = widget.availability!.endTime;
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDay) {
      setState(() {
        _selectedDay = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _selectedDay!,
        _startTimeController.text,
        _endTimeController.text,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      title: Text(
        widget.availability == null
            ? 'Adicionar Disponibilidade'
            : 'Editar Disponibilidade',
        style: AppTheme.headingMedium,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Day of week
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Dia',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDay != null
                      ? '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                      : 'Selecione um dia',
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Start and end time
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Início (HH:mm)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obrigatório';
                      }
                      if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$')
                          .hasMatch(value)) {
                        return 'Formato inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Fim (HH:mm)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obrigatório';
                      }
                      if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$')
                          .hasMatch(value)) {
                        return 'Formato inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            'Salvar',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
