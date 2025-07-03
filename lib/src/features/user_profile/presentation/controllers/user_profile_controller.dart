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

    try {
      _userProfile = await _repository.getUserProfile();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(UserProfile userProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateUserProfile(userProfile);
      _userProfile = userProfile;
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
