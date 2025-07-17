
import 'package:flutter/material.dart';

class FieldSelectionProvider with ChangeNotifier {
  bool _isFieldDetailsVisible = false;

  bool get isFieldDetailsVisible => _isFieldDetailsVisible;

  void showFieldDetails() {
    _isFieldDetailsVisible = true;
    notifyListeners();
  }

  void hideFieldDetails() {
    _isFieldDetailsVisible = false;
    notifyListeners();
  }
}
