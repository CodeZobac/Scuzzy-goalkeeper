import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/theme/app_theme.dart';
import '../../../auth/presentation/widgets/auth_layout.dart';
import '../controllers/availability_controller.dart';
import '../widgets/availability_widgets.dart';
import '../widgets/availability_form_dialog.dart';
import '../../data/repositories/availability_repository.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late AvailabilityController _controller;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _controller = AvailabilityController(AvailabilityRepository());
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (_currentUserId != null) {
      _controller.loadFutureAvailabilities(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AvailabilityFormDialog(
        onSave: (day, startTime, endTime) async {
          if (_currentUserId != null) {
            await _controller.addAvailability(
              goalkeeperId: _currentUserId!,
              day: day,
              startTime: startTime,
              endTime: endTime,
            );
          }
        },
      ),
    );
  }

  Future<void> _showEditDialog(availability) async {
    await showDialog(
      context: context,
      builder: (context) => AvailabilityFormDialog(
        availability: availability,
        onSave: (day, startTime, endTime) async {
          final updatedAvailability = availability.copyWith(
            day: day,
            startTime: startTime,
            endTime: endTime,
          );
          await _controller.updateAvailability(updatedAvailability);
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(availability) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: Text(
          'Remover Disponibilidade',
          style: AppTheme.headingMedium,
        ),
        content: Text(
          'Tem certeza que deseja remover esta disponibilidade?\n\n'
          '${availability.formattedDay}\n'
          '${availability.formattedTimeRange}',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.secondaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Remover',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.deleteAvailability(availability.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minha Disponibilidade',
                              style: AppTheme.headingLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gerir os seus horários disponíveis',
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: _showAddDialog,
                        backgroundColor: AppTheme.accentColor,
                        elevation: 0,
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Consumer<AvailabilityController>(
                    builder: (context, controller, _) {
                      // Show error if exists
                      if (controller.error != null) {
                        return AvailabilityErrorState(
                          error: controller.error!,
                          onRetry: () {
                            if (_currentUserId != null) {
                              controller.loadFutureAvailabilities(_currentUserId!);
                            }
                          },
                        );
                      }

                      // Show loading
                      if (controller.isLoading) {
                        return const AvailabilityLoadingState();
                      }

                      // Show empty state
                      if (controller.availabilities.isEmpty) {
                        return EmptyAvailabilityState(
                          onAddPressed: _showAddDialog,
                        );
                      }

                      // Show availabilities list
                      return RefreshIndicator(
                        onRefresh: () async {
                          if (_currentUserId != null) {
                            await controller.refresh(_currentUserId!);
                          }
                        },
                        color: AppTheme.accentColor,
                        backgroundColor: AppTheme.secondaryBackground,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: controller.availabilities.length,
                          itemBuilder: (context, index) {
                            final availability = controller.availabilities[index];
                            
                            return FadeInSlideUp(
                              delay: Duration(milliseconds: 100 * index),
                              child: AvailabilityCard(
                                availability: availability,
                                onEdit: () => _showEditDialog(availability),
                                onDelete: () => _showDeleteDialog(availability),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AvailabilityManagementPage extends StatefulWidget {
  const AvailabilityManagementPage({super.key});

  @override
  State<AvailabilityManagementPage> createState() => _AvailabilityManagementPageState();
}

class _AvailabilityManagementPageState extends State<AvailabilityManagementPage> {
  late AvailabilityController _controller;
  String? _currentUserId;
  bool _showPastAvailabilities = false;

  @override
  void initState() {
    super.initState();
    _controller = AvailabilityController(AvailabilityRepository());
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (_currentUserId != null) {
      _loadAvailabilities();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAvailabilities() async {
    if (_currentUserId != null) {
      if (_showPastAvailabilities) {
        await _controller.loadAvailabilities(_currentUserId!);
      } else {
        await _controller.loadFutureAvailabilities(_currentUserId!);
      }
    }
  }

  Future<void> _togglePastAvailabilities() async {
    setState(() {
      _showPastAvailabilities = !_showPastAvailabilities;
    });
    await _loadAvailabilities();
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AvailabilityFormDialog(
        onSave: (day, startTime, endTime) async {
          if (_currentUserId != null) {
            final success = await _controller.addAvailability(
              goalkeeperId: _currentUserId!,
              day: day,
              startTime: startTime,
              endTime: endTime,
            );
            
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Disponibilidade adicionada com sucesso!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showEditDialog(availability) async {
    await showDialog(
      context: context,
      builder: (context) => AvailabilityFormDialog(
        availability: availability,
        onSave: (day, startTime, endTime) async {
          final updatedAvailability = availability.copyWith(
            day: day,
            startTime: startTime,
            endTime: endTime,
          );
          
          final success = await _controller.updateAvailability(updatedAvailability);
          
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Disponibilidade atualizada com sucesso!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(availability) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: Text(
          'Remover Disponibilidade',
          style: AppTheme.headingMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja remover esta disponibilidade?',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    availability.formattedDay,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    availability.formattedTimeRange,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.secondaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.errorColor.withOpacity(0.1),
            ),
            child: Text(
              'Remover',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _controller.deleteAvailability(availability.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disponibilidade removida com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minha Disponibilidade',
                                  style: AppTheme.headingLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gerir os seus horários disponíveis',
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          FloatingActionButton(
                            onPressed: _showAddDialog,
                            backgroundColor: AppTheme.accentColor,
                            elevation: 0,
                            heroTag: "add_availability",
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Filter Toggle
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _showPastAvailabilities 
                                  ? 'Mostrando todas as disponibilidades'
                                  : 'Mostrando apenas disponibilidades futuras',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ),
                          Switch(
                            value: _showPastAvailabilities,
                            onChanged: (_) => _togglePastAvailabilities(),
                            activeColor: AppTheme.accentColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Consumer<AvailabilityController>(
                    builder: (context, controller, _) {
                      // Show error if exists
                      if (controller.error != null) {
                        return AvailabilityErrorState(
                          error: controller.error!,
                          onRetry: _loadAvailabilities,
                        );
                      }

                      // Show loading
                      if (controller.isLoading) {
                        return const AvailabilityLoadingState();
                      }

                      // Show empty state
                      if (controller.availabilities.isEmpty) {
                        return EmptyAvailabilityState(
                          message: _showPastAvailabilities 
                              ? 'Ainda não tem disponibilidades definidas.'
                              : 'Não tem disponibilidades futuras.',
                          onAddPressed: _showAddDialog,
                        );
                      }

                      // Show availabilities list
                      return RefreshIndicator(
                        onRefresh: () async {
                          if (_currentUserId != null) {
                            await controller.refresh(_currentUserId!);
                          }
                        },
                        color: AppTheme.accentColor,
                        backgroundColor: AppTheme.secondaryBackground,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: controller.availabilities.length,
                          itemBuilder: (context, index) {
                            final availability = controller.availabilities[index];
                            
                            return FadeInSlideUp(
                              delay: Duration(milliseconds: 50 * index),
                              child: AvailabilityCard(
                                availability: availability,
                                onEdit: availability.isPast ? null : () => _showEditDialog(availability),
                                onDelete: () => _showDeleteDialog(availability),
                                showActions: true,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
