import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/map_controller.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class FieldSuggestionSheet extends StatefulWidget {
  final MapController mapController;

  const FieldSuggestionSheet({
    Key? key,
    required this.mapController,
  }) : super(key: key);

  @override
  State<FieldSuggestionSheet> createState() => _FieldSuggestionSheetState();
}

class _FieldSuggestionSheetState extends State<FieldSuggestionSheet> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _surfaceTypes = [
    'natural',
    'artificial',
    'synthetic',
    'sand',
    'indoor',
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.mapController,
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.borderRadius * 2),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(AppTheme.spacing),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppTheme.spacing),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryText,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Title
                  Text(
                    'Sugerir Novo Campo',
                    style: AppTheme.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AppTheme.spacing),
                  
                  // Form
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildTextField(
                            controller: widget.mapController.nameController,
                            label: 'Nome do Campo',
                            hint: 'Ex: Campo do Maracanã',
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Nome é obrigatório';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppTheme.spacing),
                          
                          _buildTextField(
                            controller: widget.mapController.descriptionController,
                            label: 'Descrição (Opcional)',
                            hint: 'Descreva as características do campo',
                            maxLines: 3,
                          ),
                          
                          const SizedBox(height: AppTheme.spacing),
                          
                          _buildTextField(
                            controller: widget.mapController.photoUrlController,
                            label: 'URL da Foto (Opcional)',
                            hint: 'https://exemplo.com/foto.jpg',
                          ),
                          
                          const SizedBox(height: AppTheme.spacing),
                          
                          _buildSurfaceTypeDropdown(),
                          
                          const SizedBox(height: AppTheme.spacing),
                          
                          _buildTextField(
                            controller: widget.mapController.dimensionsController,
                            label: 'Dimensões (Opcional)',
                            hint: 'Ex: 100m x 60m',
                          ),
                          
                          const SizedBox(height: AppTheme.spacing),
                          
                          _buildLocationInfo(),
                          
                          const SizedBox(height: AppTheme.spacingLarge),
                          
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
          ),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSurfaceTypeDropdown() {
    return Consumer<MapController>(
      builder: (context, controller, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Superfície',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBackground,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedSurfaceType,
                  isExpanded: true,
                  dropdownColor: AppTheme.secondaryBackground,
                  items: _surfaceTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        _getSurfaceTypeLabel(type),
                        style: AppTheme.bodyLarge,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.setSurfaceType(value);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationInfo() {
    return Consumer<MapController>(
      builder: (context, controller, _) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacing),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    'Localização Selecionada',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                'Latitude: ${controller.selectedLatitude?.toStringAsFixed(6) ?? 'Não selecionada'}',
                style: AppTheme.bodyMedium,
              ),
              Text(
                'Longitude: ${controller.selectedLongitude?.toStringAsFixed(6) ?? 'Não selecionada'}',
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<MapController>(
      builder: (context, controller, _) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: controller.canSubmitField
                ? () => _submitField(controller)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.canSubmitField
                  ? AppTheme.accentColor
                  : AppTheme.secondaryText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
            child: controller.loadingState == MapLoadingState.loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Enviar Sugestão',
                    style: AppTheme.buttonText,
                  ),
          ),
        );
      },
    );
  }

  String _getSurfaceTypeLabel(String type) {
    switch (type) {
      case 'natural':
        return 'Grama Natural';
      case 'artificial':
        return 'Grama Artificial';
      case 'synthetic':
        return 'Sintético';
      case 'sand':
        return 'Areia';
      case 'indoor':
        return 'Indoor';
      default:
        return type;
    }
  }

  Future<void> _submitField(MapController controller) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await controller.submitFieldSuggestion();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sugestão enviada com sucesso!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar sugestão: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
          ),
        );
      }
    }
  }
}
