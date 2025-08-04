import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../data/models/announcement.dart';
import '../controllers/announcement_controller.dart';
import '../widgets/organizer_profile.dart';
import '../widgets/game_details_row.dart';
import '../widgets/participant_avatar_row.dart';
import '../widgets/stadium_card.dart';
import '../widgets/loading_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../shared/widgets/registration_prompt_dialog.dart';
import '../../../../shared/helpers/registration_prompt_helper.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late Announcement _announcement;
  bool _isLoadingDetails = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;
    _checkJoinStatus();
    _loadAnnouncementDetails();
    _markAnnouncementAsViewed();
  }

  Future<void> _markAnnouncementAsViewed() async {
    final authProvider = Provider.of<AuthStateProvider>(context, listen: false);
    if (authProvider.isGuest) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final controller = Provider.of<AnnouncementController>(context, listen: false);
      await controller.markAnnouncementAsViewed(_announcement.id, userId);
    } catch (e) {
      // Silently handle error - view tracking is not critical
    }
  }

  Future<void> _loadAnnouncementDetails() async {
    setState(() {
      _isLoadingDetails = true;
      _errorMessage = null;
    });

    try {
      final announcementController =
          Provider.of<AnnouncementController>(context, listen: false);
      final updatedAnnouncement = await announcementController.getAnnouncementById(_announcement.id);
      
      if (mounted) {
        setState(() {
          _announcement = updatedAnnouncement;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AnnouncementErrorHandler.getErrorMessage(e);
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _checkJoinStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final announcementController =
          Provider.of<AnnouncementController>(context, listen: false);
      try {
        await announcementController.checkUserParticipation(_announcement.id, userId);
      } catch (e) {
        // Handle error silently or show a message
      }
    }
  }



  Future<void> _toggleJoinStatus() async {
    final authStateProvider = Provider.of<AuthStateProvider>(context, listen: false);
    
    // Check if user is guest and show registration prompt
    if (authStateProvider.isGuest) {
      await RegistrationPromptHelper.showJoinMatchPrompt(context);
      return;
    }
    
    final announcementController =
        Provider.of<AnnouncementController>(context, listen: false);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to join announcements')),
      );
      return;
    }

    try {
      final isCurrentlyJoined = announcementController.isUserParticipant(_announcement.id);
      
      if (isCurrentlyJoined) {
        await announcementController.leaveAnnouncement(_announcement.id, userId);
        if (mounted) {
          AnnouncementErrorHandler.showSuccessSnackBar(
            context,
            AppLocalizations.of(context)!.successfullyLeftEvent,
          );
        }
      } else {
        await announcementController.joinAnnouncement(_announcement.id, userId);
        if (mounted) {
          AnnouncementErrorHandler.showSuccessSnackBar(
            context,
            AppLocalizations.of(context)!.successfullyJoinedEvent,
          );
        }
      }
      
      // Refresh the announcement data
      final updatedAnnouncement = await announcementController.getAnnouncementById(_announcement.id);
      setState(() {
        _announcement = updatedAnnouncement;
      });
      
    } catch (e) {
      if (mounted) {
        AnnouncementErrorHandler.showErrorSnackBar(
          context,
          AnnouncementErrorHandler.getErrorMessage(e),
        );
      }
    }
  }

  void _onMapTap() {
    // Navigate to map screen using NavigationService with field coordinates
    NavigationService.pushToMap(
      context,
      fieldLatitude: _announcement.fieldLatitude,
      fieldLongitude: _announcement.fieldLongitude,
      fieldName: _announcement.stadium,
    );
  }

  Widget _buildLoadingState() {
    return const LoadingStateWidget(
      message: 'Loading announcement details...',
    );
  }

  Widget _buildErrorState() {
    return ErrorStateWidget(
      errorMessage: _errorMessage,
      title: 'Failed to load details',
      onRetry: () => _loadAnnouncementDetails(),
      isRetrying: _isLoadingDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with organizer profile
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: OrganizerProfile(
                name: _announcement.organizerName ?? 'Organizer',
                avatarUrl: _announcement.organizerAvatarUrl,
                rating: _announcement.organizerRating,
                showBackButton: true,
                avatarSize: 48,
              ),
            ),
            
            // Scrollable content
            Expanded(
              child: _isLoadingDetails
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              
                              // White content card
                              Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(

                            color: Colors.black.withOpacity(0.05),

                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              _announcement.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Description
                            if (_announcement.description != null)
                              Text(
                                _announcement.description!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                  height: 1.5,
                                ),
                              ),
                            const SizedBox(height: 20),
                            
                            // Game details row with icons
                            GameDetailsRow(
                              date: _announcement.date,
                              time: _announcement.time,
                              price: _announcement.price,
                              showLargeIcons: true,
                            ),
                            const SizedBox(height: 24),
                            
                            // Participant section
                            ParticipantAvatarRow(
                              participants: _announcement.participants,
                              participantCount: _announcement.participantCount,
                              maxParticipants: _announcement.maxParticipants,
                              maxVisible: 4,
                              onTap: () {
                                // TODO: Show full participant list
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Join Event button
                            Consumer2<AnnouncementController, AuthStateProvider>(
                              builder: (context, controller, authProvider, child) {
                                final isLoading = controller.isJoinLeaveLoading(_announcement.id);
                                final isJoined = !authProvider.isGuest && controller.isUserParticipant(_announcement.id);
                                final isFull = _announcement.participantCount >= _announcement.maxParticipants;
                                final isGuest = authProvider.isGuest;
                                final isGameEnded = _announcement.status != 'active';
                                
                                return SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: (isLoading || (isFull && !isJoined && !isGuest) || isGameEnded) ? null : _toggleJoinStatus,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isGameEnded
                                          ? (_announcement.status == 'completed' 
                                              ? const Color(0xFF4CAF50) // Green for completed games
                                              : const Color(0xFFE57373)) // Light red for terminated games
                                          : isJoined 
                                              ? const Color(0xFF757575) 
                                              : (isFull && !isJoined && !isGuest)
                                                  ? const Color(0xFF9E9E9E) // Darker gray for better contrast
                                                  : const Color(0xFFFF9800),
                                      foregroundColor: isGameEnded
                                          ? Colors.white
                                          : Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            isGameEnded
                                                ? (_announcement.status == 'completed' ? AppLocalizations.of(context)!.gameFinished : AppLocalizations.of(context)!.gameCancelled)
                                                : isGuest
                                                    ? AppLocalizations.of(context)!.joinEvent
                                                    : isJoined 
                                                        ? AppLocalizations.of(context)!.leaveEvent
                                                        : (isFull && !isJoined)
                                                            ? AppLocalizations.of(context)!.eventFull
                                                            : AppLocalizations.of(context)!.joinEvent,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_announcement.createdBy == Supabase.instance.client.auth.currentUser?.id && 
                                _announcement.status == 'active')
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final announcementController =
                                        Provider.of<AnnouncementController>(context, listen: false);
                                    try {
                                      await announcementController.endGame(_announcement.id);
                                      if (mounted) {
                                        AnnouncementErrorHandler.showSuccessSnackBar(
                                          context,
                                          AppLocalizations.of(context)!.gameEndedSuccessfully,
                                        );
                                        // Navigate back since the game is now terminated
                                        Navigator.of(context).pop();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        AnnouncementErrorHandler.showErrorSnackBar(
                                          context,
                                          AnnouncementErrorHandler.getErrorMessage(e),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.endGame,
                                    style: const TextStyle(
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
                    
                    const SizedBox(height: 16),
                    
                    // Stadium section with green background
                    if (_announcement.stadium != null)
                      StadiumCard(
                        stadiumName: _announcement.stadium!,
                        imageUrl: _announcement.stadiumImageUrl,
                        distance: _announcement.distanceKm,
                        fieldLatitude: _announcement.fieldLatitude,
                        fieldLongitude: _announcement.fieldLongitude,
                        fieldPhotoUrl: _announcement.fieldPhotoUrl,
                        onMapTap: _onMapTap,
                      ),
                    
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
