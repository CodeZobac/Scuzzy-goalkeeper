import 'package:flutter/material.dart';
import '../../data/models/announcement.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../utils/error_handler.dart';

class AnnouncementController extends ChangeNotifier {
  final AnnouncementRepository _announcementRepository;

  AnnouncementController(this._announcementRepository);

  List<Announcement> _announcements = [];
  List<Announcement> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error state management
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Loading states for different operations
  bool _isCreatingAnnouncement = false;
  bool get isCreatingAnnouncement => _isCreatingAnnouncement;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  // Track join/leave loading states for individual announcements
  final Map<int, bool> _joinLeaveLoadingStates = {};
  bool isJoinLeaveLoading(int announcementId) => _joinLeaveLoadingStates[announcementId] ?? false;

  // Track user participation status for announcements
  final Map<int, bool> _participationStatus = {};
  bool isUserParticipant(int announcementId) => _participationStatus[announcementId] ?? false;

  // Track individual announcement loading states
  final Map<int, bool> _announcementLoadingStates = {};
  bool isAnnouncementLoading(int announcementId) => _announcementLoadingStates[announcementId] ?? false;

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _announcements = await _announcementRepository.getAnnouncements();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = AnnouncementErrorHandler.getErrorMessage(e);
      _announcements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createAnnouncement(Announcement announcement) async {
    _isCreatingAnnouncement = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _announcementRepository.createAnnouncement(announcement);
      await fetchAnnouncements();
    } catch (e) {
      _errorMessage = AnnouncementErrorHandler.getErrorMessage(e);
      rethrow;
    } finally {
      _isCreatingAnnouncement = false;
      notifyListeners();
    }
  }

  /// Refresh announcements with pull-to-refresh functionality
  Future<void> refreshAnnouncements() async {
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _announcements = await _announcementRepository.getAnnouncements();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = AnnouncementErrorHandler.getErrorMessage(e);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Retry failed operations
  Future<void> retry() async {
    if (hasError) {
      await fetchAnnouncements();
    }
  }

  /// Clear error state
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if user is participant in a specific announcement
  Future<bool> checkUserParticipation(int announcementId, String userId) async {
    try {
      final isParticipant = await _announcementRepository.isUserParticipant(announcementId, userId);
      _participationStatus[announcementId] = isParticipant;
      notifyListeners();
      return isParticipant;
    } catch (e) {
      rethrow;
    }
  }

  /// Join an announcement with proper validation and state management
  Future<void> joinAnnouncement(int announcementId, String userId) async {
    // Set loading state
    _joinLeaveLoadingStates[announcementId] = true;
    notifyListeners();

    try {
      // Get current announcement to check participant limit
      final announcement = await _announcementRepository.getAnnouncementById(announcementId);
      
      // Validate participant limit
      if (announcement.participantCount >= announcement.maxParticipants) {
        throw Exception('This announcement is full. Cannot join.');
      }

      // Check if user is already a participant
      final isAlreadyParticipant = await _announcementRepository.isUserParticipant(announcementId, userId);
      if (isAlreadyParticipant) {
        throw Exception('You are already a participant in this announcement.');
      }

      // Join the announcement
      await _announcementRepository.joinAnnouncement(announcementId, userId);
      
      // Update local state
      _participationStatus[announcementId] = true;
      
      // Update the announcement in the local list
      await _refreshAnnouncementById(announcementId);
      
    } catch (e) {
      rethrow;
    } finally {
      // Clear loading state
      _joinLeaveLoadingStates[announcementId] = false;
      notifyListeners();
    }
  }

  /// Leave an announcement with proper state management
  Future<void> leaveAnnouncement(int announcementId, String userId) async {
    // Set loading state
    _joinLeaveLoadingStates[announcementId] = true;
    notifyListeners();

    try {
      // Check if user is actually a participant
      final isParticipant = await _announcementRepository.isUserParticipant(announcementId, userId);
      if (!isParticipant) {
        throw Exception('You are not a participant in this announcement.');
      }

      // Leave the announcement
      await _announcementRepository.leaveAnnouncement(announcementId, userId);
      
      // Update local state
      _participationStatus[announcementId] = false;
      
      // Update the announcement in the local list
      await _refreshAnnouncementById(announcementId);
      
    } catch (e) {
      rethrow;
    } finally {
      // Clear loading state
      _joinLeaveLoadingStates[announcementId] = false;
      notifyListeners();
    }
  }

  /// Refresh a specific announcement by ID to get updated participant data
  Future<void> _refreshAnnouncementById(int announcementId) async {
    try {
      final updatedAnnouncement = await _announcementRepository.getAnnouncementById(announcementId);
      
      // Find and update the announcement in the local list
      final index = _announcements.indexWhere((a) => a.id == announcementId);
      if (index != -1) {
        _announcements[index] = updatedAnnouncement;
      }
    } catch (e) {
      // If we can't refresh the specific announcement, we could refresh all
      // or just log the error - for now we'll silently continue
    }
  }

  /// Get detailed announcement by ID
  Future<Announcement> getAnnouncementById(int announcementId) async {
    return await _announcementRepository.getAnnouncementById(announcementId);
  }

  Future<List<String>> getAnnouncementParticipants(int announcementId) async {
    return await _announcementRepository.getAnnouncementParticipants(announcementId);
  }

  /// Get participants with full details
  Future<List<AnnouncementParticipant>> getParticipants(int announcementId) async {
    return await _announcementRepository.getParticipants(announcementId);
  }

  /// Clear participation status cache (useful when user logs out)
  void clearParticipationCache() {
    _participationStatus.clear();
    _joinLeaveLoadingStates.clear();
    notifyListeners();
  }

  Future<void> endGame(int announcementId) async {
    try {
      await _announcementRepository.endGame(announcementId);
    } catch (e) {
      rethrow;
    }
  }
}
