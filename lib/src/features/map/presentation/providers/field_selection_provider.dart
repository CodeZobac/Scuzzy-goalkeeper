import 'package:flutter/material.dart';
import '../../domain/models/map_field.dart';

class FieldSelectionProvider extends ChangeNotifier {
  MapField? _selectedField;
  bool _isFieldDetailsVisible = false;

  MapField? get selectedField => _selectedField;
  bool get isFieldDetailsVisible => _isFieldDetailsVisible;

  void selectField(MapField field) {
    _selectedField = field;
    _isFieldDetailsVisible = true;
    notifyListeners();
  }

  void clearSelection() {
    _selectedField = null;
    _isFieldDetailsVisible = false;
    notifyListeners();
  }
}
