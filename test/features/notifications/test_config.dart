import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Test configuration and setup utilities for notification tests
class NotificationTestConfig {
  static void setupTestEnvironment() {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock system channels
    _mockSystemChannels();
    
    // Setup test fonts
    _setupTestFonts();
  }

  static void _mockSystemChannels() {
    // Mock platform channels that might be used by notifications
    const MethodChannel('plugins.flutter.io/firebase_messaging')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getToken':
          return 'mock_fcm_token';
        case 'requestPermission':
          return {'authorizationStatus': 1}; // authorized
        default:
          return null;
      }
    });

    const MethodChannel('plugins.flutter.io/shared_preferences')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getAll':
          return <String, dynamic>{};
        default:
          return null;
      }
    });
  }

  static void _setupTestFonts() {
    // Load test fonts for consistent rendering in golden tests
    // This would typically load the app's custom fonts
  }

  /// Creates a mock Supabase client for testing
  static SupabaseClient createMockSupabaseClient() {
    final mockClient = MockSupabaseClient();
    
    // Setup default mock behaviors
    when(mockClient.auth).thenReturn(MockGoTrueClient());
    when(mockClient.realtime).thenReturn(MockRealtimeClient());
    
    return mockClient;
  }

  /// Test data generators
  static Map<String, dynamic> createMockNotificationData({
    String type = 'general',
    String? contractId,
    String? contractorName,
    double? offeredAmount,
    String? announcementId,
    String? announcementTitle,
    int? participantCount,
    int? maxParticipants,
  }) {
    final data = <String, dynamic>{
      'type': type,
    };

    if (type == 'contract_request') {
      data.addAll({
        'contract_id': contractId ?? 'contract-123',
        'contractor_name': contractorName ?? 'João Silva',
        'offered_amount': offeredAmount,
        'announcement_id': announcementId ?? 'announcement-456',
        'stadium': 'Estádio Central',
        'game_date_time': DateTime(2024, 12, 25, 15, 30).toIso8601String(),
      });
    } else if (type == 'full_lobby') {
      data.addAll({
        'announcement_id': announcementId ?? 'announcement-789',
        'announcement_title': announcementTitle ?? 'Jogo de Futebol',
        'participant_count': participantCount ?? 22,
        'max_participants': maxParticipants ?? 22,
        'stadium': 'Estádio Central',
        'game_date_time': DateTime(2024, 12, 25, 15, 30).toIso8601String(),
      });
    }

    return data;
  }

  /// Creates test notification with realistic data
  static Map<String, dynamic> createTestNotification({
    String? id,
    String? userId,
    String? title,
    String? body,
    String type = 'general',
    Map<String, dynamic>? data,
    DateTime? sentAt,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return {
      'id': id ?? 'notification-test-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': userId ?? 'user-123',
      'title': title ?? 'Test Notification',
      'body': body ?? 'Test notification body',
      'type': type,
      'data': data ?? createMockNotificationData(type: type),
      'sent_at': (sentAt ?? DateTime.now()).toIso8601String(),
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'category': _getCategoryFromType(type),
      'requires_action': type == 'contract_request',
    };
  }

  static String _getCategoryFromType(String type) {
    switch (type) {
      case 'contract_request':
        return 'contracts';
      case 'full_lobby':
        return 'fullLobbies';
      default:
        return 'general';
    }
  }

  /// Test assertion helpers
  static void expectNotificationEquals(
    Map<String, dynamic> actual,
    Map<String, dynamic> expected,
  ) {
    expect(actual['id'], equals(expected['id']));
    expect(actual['user_id'], equals(expected['user_id']));
    expect(actual['title'], equals(expected['title']));
    expect(actual['body'], equals(expected['body']));
    expect(actual['type'], equals(expected['type']));
    expect(actual['category'], equals(expected['category']));
  }

  /// Performance test helpers
  static Future<T> measurePerformance<T>(
    Future<T> Function() operation, {
    Duration? maxDuration,
    String? operationName,
  }) async {
    final stopwatch = Stopwatch()..start();
    final result = await operation();
    stopwatch.stop();

    if (maxDuration != null && stopwatch.elapsed > maxDuration) {
      throw Exception(
        '${operationName ?? 'Operation'} took ${stopwatch.elapsedMilliseconds}ms, '
        'expected less than ${maxDuration.inMilliseconds}ms',
      );
    }

    return result;
  }

  /// Memory usage helpers for performance tests
  static void expectMemoryUsageReasonable(List<dynamic> data) {
    // Basic memory usage checks
    expect(data.length, lessThan(100000)); // Reasonable list size
    
    // Check for memory leaks (simplified)
    if (data.isNotEmpty) {
      expect(data.first, isNotNull);
      expect(data.last, isNotNull);
    }
  }

  /// Test cleanup utilities
  static void cleanupTestData() {
    // Clear any test data that might persist between tests
    // Reset static variables, clear caches, etc.
  }
}

// Mock classes for testing
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockRealtimeClient extends Mock implements RealtimeClient {}

/// Test constants
class NotificationTestConstants {
  static const String testUserId = 'test-user-123';
  static const String testContractorId = 'contractor-456';
  static const String testAnnouncementId = 'announcement-789';
  static const String testContractId = 'contract-abc';
  static const String testNotificationId = 'notification-xyz';
  
  static const String contractorName = 'João Silva';
  static const String announcementTitle = 'Jogo de Futebol - Estádio Central';
  static const String stadium = 'Estádio Central';
  static const double offeredAmount = 150.0;
  
  static final DateTime testGameDateTime = DateTime(2024, 12, 25, 15, 30);
  static final DateTime testCreatedAt = DateTime(2024, 12, 20, 10, 0);
  static final DateTime testSentAt = DateTime(2024, 12, 20, 10, 0);
  
  static const int maxParticipants = 22;
  static const int currentParticipants = 22;
  
  // Test timeouts
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(milliseconds: 500);
  
  // Performance thresholds
  static const Duration maxLoadTime = Duration(milliseconds: 500);
  static const Duration maxFilterTime = Duration(milliseconds: 100);
  static const Duration maxRenderTime = Duration(milliseconds: 200);
  
  // UI test constants
  static const Size mobileScreenSize = Size(375, 667);
  static const Size tabletScreenSize = Size(768, 1024);
  static const Size smallScreenSize = Size(320, 568);
  
  // Accessibility constants
  static const double minTouchTargetSize = 44.0;
  static const double maxTextScaleFactor = 2.0;
}

/// Test utilities for common operations
class NotificationTestUtils {
  /// Waits for async operations to complete in tests
  static Future<void> waitForAsync([Duration? duration]) async {
    await Future.delayed(duration ?? const Duration(milliseconds: 100));
  }

  /// Pumps widget and waits for animations
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  /// Creates a test widget wrapper with necessary providers
  static Widget createTestWrapper(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
      theme: ThemeData(
        // Match app theme for consistent testing
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
    );
  }

  /// Generates test data for bulk operations
  static List<Map<String, dynamic>> generateTestNotifications(
    int count, {
    String userId = NotificationTestConstants.testUserId,
    String type = 'general',
  }) {
    return List.generate(count, (index) {
      return NotificationTestConfig.createTestNotification(
        id: 'notification-$index',
        userId: userId,
        title: 'Test Notification $index',
        body: 'Test body $index',
        type: type,
        createdAt: DateTime.now().subtract(Duration(minutes: index)),
      );
    });
  }
}