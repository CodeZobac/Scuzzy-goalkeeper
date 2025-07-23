import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:goalkeeper/src/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_category.dart';

import 'notifications_screen_test.mocks.dart';

@GenerateMocks([NotificationController])
void main() {
  group('NotificationsScreen', () {
    late MockNotificationController mockController;

    setUp(() {
      mockController = MockNotificationController();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<NotificationController>.value(
          value: mockController,
          child: const NotificationsScreen(),
        ),
      );
    }

    group('UI Rendering', () {
      testWidgets('should display app bar with correct title', (tester) async {
        // Arrange
        when(mockController.notifications).thenReturn([]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Notificações'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should display loading indicator when loading', (tester) async {
        // Arrange
        when(mockController.notifications).thenReturn([]);
        when(mockController.isLoading).thenReturn(true);
        when(mockController.error).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display error message when error occurs', (tester) async {
        // Arrange
        when(mockController.notifications).thenReturn([]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn('Network error');

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Erro ao carregar notificações'), findsOneWidget);
        expect(find.text('Tentar novamente'), findsOneWidget);
      });

      testWidgets('should display empty state when no notifications', (tester) async {
        // Arrange
        when(mockController.notifications).thenReturn([]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Nenhuma notificação'), findsOneWidget);
        expect(find.text('Você não tem notificações no momento'), findsOneWidget);
      });
    });

    group('Notification Categories', () {
      testWidgets('should display category tabs', (tester) async {
        // Arrange
        when(mockController.notifications).thenReturn([]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(0);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Contratos'), findsOneWidget);
        expect(find.text('Lobbies Completos'), findsOneWidget);
        expect(find.text('Geral'), findsOneWidget);
      });

      testWidgets('should display category count badges', (tester) async {
        // Arrange
        when(mockController.notifications).thenReturn([]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(NotificationCategory.contracts)).thenReturn(3);
        when(mockController.getCategoryCount(NotificationCategory.fullLobbies)).thenReturn(1);
        when(mockController.getCategoryCount(NotificationCategory.general)).thenReturn(0);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('3'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('should filter notifications by selected category', (tester) async {
        // Arrange
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Contract Request',
          body: 'New contract available',
          type: 'contract_request',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockController.notifications).thenReturn([contractNotification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(NotificationCategory.contracts))
            .thenReturn([contractNotification]);
        when(mockController.getNotificationsByCategory(NotificationCategory.fullLobbies))
            .thenReturn([]);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Contratos'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Contract Request'), findsOneWidget);
      });
    });

    group('Notification Cards', () {
      testWidgets('should display contract notification cards', (tester) async {
        // Arrange
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: {
            'contract_id': 'contract-123',
            'contractor_name': 'João Silva',
            'offered_amount': 150.0,
            'stadium': 'Estádio Central',
          },
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockController.notifications).thenReturn([contractNotification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(any))
            .thenReturn([contractNotification]);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Nova Proposta de Contrato'), findsOneWidget);
        expect(find.text('João Silva quer contratá-lo'), findsOneWidget);
        expect(find.text('Aceitar'), findsOneWidget);
        expect(find.text('Recusar'), findsOneWidget);
      });

      testWidgets('should display full lobby notification cards', (tester) async {
        // Arrange
        final lobbyNotification = AppNotification(
          id: 'notification-2',
          userId: 'user-123',
          title: 'Lobby Completo!',
          body: 'Seu anúncio está cheio',
          type: 'full_lobby',
          data: {
            'announcement_id': 'announcement-456',
            'announcement_title': 'Jogo de Futebol',
            'participant_count': 22,
            'max_participants': 22,
          },
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockController.notifications).thenReturn([lobbyNotification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(any))
            .thenReturn([lobbyNotification]);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Lobby Completo!'), findsOneWidget);
        expect(find.text('Seu anúncio está cheio'), findsOneWidget);
        expect(find.text('Ver Detalhes'), findsOneWidget);
      });

      testWidgets('should show unread indicator for unread notifications', (tester) async {
        // Arrange
        final unreadNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Unread Notification',
          body: 'This is unread',
          type: 'contract_request',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null, // Unread
        );

        when(mockController.notifications).thenReturn([unreadNotification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(any))
            .thenReturn([unreadNotification]);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(Badge), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('should handle contract acceptance', (tester) async {
        // Arrange
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: {
            'contract_id': 'contract-123',
            'contractor_name': 'João Silva',
          },
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockController.notifications).thenReturn([contractNotification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(any))
            .thenReturn([contractNotification]);
        when(mockController.handleContractResponse(any, any, any))
            .thenAnswer((_) async => {});

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Aceitar'));
        await tester.pumpAndSettle();

        // Assert
        verify(mockController.handleContractResponse(
          'notification-1',
          'contract-123',
          true,
        )).called(1);
      });

      testWidgets('should handle contract decline', (tester) async {
        // Arrange
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: {
            'contract_id': 'contract-123',
            'contractor_name': 'João Silva',
          },
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockController.notifications).thenReturn([contractNotification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(any))
            .thenReturn([contractNotification]);
        when(mockController.handleContractResponse(any, any, any))
            .thenAnswer((_) async => {});

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Recusar'));
        await tester.pumpAndSettle();

        // Assert
        verify(mockController.handleContractResponse(
          'notification-1',
          'contract-123',
          false,
        )).called(1);
      });

      testWidgets('should mark notification as read when tapped', (tester) async {
        // Arrange
        final notification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Test Notification',
          body: 'Test body',
          type: 'general',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockController.notifications).thenReturn([notification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(any))
            .thenReturn([notification]);
        when(mockController.markAsRead(any))
            .thenAnswer((_) async => {});

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Test Notification'));
        await tester.pumpAndSettle();

        // Assert
        verify(mockController.markAsRead('notification-1')).called(1);
      });

      testWidgets('should handle pull to refresh', (tester) async {
        // Arrange
        when(mockController.notifications).thenReturn([]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(0);
        when(mockController.loadNotifications(any))
            .thenAnswer((_) async => {});

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
        await tester.pumpAndSettle();

        // Assert
        verify(mockController.loadNotifications(any)).called(1);
      });
    });

    group('Visual Styling', () {
      testWidgets('should match announcement card styling', (tester) async {
        // Arrange
        final notification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Test Notification',
          body: 'Test body',
          type: 'contract_request',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockController.notifications).thenReturn([notification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(any))
            .thenReturn([notification]);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        final cardFinder = find.byType(Card);
        expect(cardFinder, findsWidgets);
        
        final card = tester.widget<Card>(cardFinder.first);
        expect(card.color, equals(Colors.white));
        expect(card.shape, isA<RoundedRectangleBorder>());
      });

      testWidgets('should display proper spacing and padding', (tester) async {
        // Arrange
        final notification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Test Notification',
          body: 'Test body',
          type: 'contract_request',
          data: {},
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockController.notifications).thenReturn([notification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(any))
            .thenReturn([notification]);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(Padding), findsWidgets);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        // Arrange
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: {
            'contract_id': 'contract-123',
            'contractor_name': 'João Silva',
          },
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockController.notifications).thenReturn([contractNotification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(any))
            .thenReturn([contractNotification]);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.bySemanticsLabel('Aceitar contrato'), findsOneWidget);
        expect(find.bySemanticsLabel('Recusar contrato'), findsOneWidget);
      });

      testWidgets('should have minimum touch target sizes', (tester) async {
        // Arrange
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: {
            'contract_id': 'contract-123',
            'contractor_name': 'João Silva',
          },
          sentAt: DateTime.now(),
          createdAt: DateTime.now(),
          readAt: null,
        );

        when(mockController.notifications).thenReturn([contractNotification]);
        when(mockController.isLoading).thenReturn(false);
        when(mockController.error).thenReturn(null);
        when(mockController.getCategoryCount(any)).thenReturn(1);
        when(mockController.getNotificationsByCategory(any))
            .thenReturn([contractNotification]);

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        final acceptButton = tester.getSize(find.text('Aceitar'));
        final declineButton = tester.getSize(find.text('Recusar'));
        
        expect(acceptButton.height, greaterThanOrEqualTo(44.0));
        expect(declineButton.height, greaterThanOrEqualTo(44.0));
      });
    });
  });
}