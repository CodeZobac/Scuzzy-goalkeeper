import 'package:flutter/material.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/user_profile_repository.dart';

class UserProfileController extends ChangeNotifier {
  final UserProfileRepository _repository;

  UserProfileController(this._repository);

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> getUserProfile() async {
    _isLoading = true;
    notifyListeners();

    const int maxRetries = 3;
    const delay = Duration(seconds: 1);

    for (int i = 0; i < maxRetries; i++) {
      try {
        _userProfile = await _repository.getUserProfile();
        // If successful, exit the loop
        break;
      } catch (e) {
        debugPrint('Attempt ${i + 1} to get user profile failed: $e');
        if (i < maxRetries - 1) {
          // Wait before the next retry
          await Future.delayed(delay);
        } else {
          debugPrint('Failed to get user profile after all retries.');
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserProfile(UserProfile userProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Ensure profileCompleted is set to true when the profile is updated.
      final updatedProfile = userProfile..profileCompleted = true;
      await _repository.updateUserProfile(updatedProfile);
      _userProfile = updatedProfile;
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
