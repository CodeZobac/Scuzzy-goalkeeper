import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/announcements/utils/error_handler.dart';

void main() {
  group('AnnouncementErrorHandler', () {
    test('should handle network errors correctly', () {
      final error = Exception('Network connection failed');
      final message = AnnouncementErrorHandler.getErrorMessage(error);
      expect(message, equals('Network connection failed'));
    });

    test('should handle timeout errors correctly', () {
      final error = Exception('Request timeout occurred');
      final message = AnnouncementErrorHandler.getErrorMessage(error);
      expect(message, equals('Request timed out. Please try again.'));
    });

    test('should handle unauthorized errors correctly', () {
      final error = Exception('401 Unauthorized access');
      final message = AnnouncementErrorHandler.getErrorMessage(error);
      expect(message, equals('Authentication required. Please log in again.'));
    });

    test('should handle server errors correctly', () {
      final error = Exception('500 Internal server error');
      final message = AnnouncementErrorHandler.getErrorMessage(error);
      expect(message, equals('Server error. Please try again later.'));
    });

    test('should handle full capacity errors correctly', () {
      final error = Exception('Event is at full capacity');
      final message = AnnouncementErrorHandler.getErrorMessage(error);
      expect(message, equals('This event is at full capacity.'));
    });

    test('should handle already joined errors correctly', () {
      final error = Exception('User already joined this event');
      final message = AnnouncementErrorHandler.getErrorMessage(error);
      expect(message, equals('You are already participating in this event.'));
    });

    test('should handle generic errors correctly', () {
      final error = Exception('Some unknown error');
      final message = AnnouncementErrorHandler.getErrorMessage(error);
      expect(message, equals('Some unknown error'));
    });

    test('should handle non-exception errors correctly', () {
      final error = 'Random string error';
      final message = AnnouncementErrorHandler.getErrorMessage(error);
      expect(message, equals('An unexpected error occurred. Please try again.'));
    });
  });
}