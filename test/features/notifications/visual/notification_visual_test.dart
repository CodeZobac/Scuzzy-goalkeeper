import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:goalkeeper/src/features/notifications/presentation/widgets/contract_notification_card.dart';
import 'package:goalkeeper/src/features/notifications/presentation/widgets/full_lobby_notification_card.dart';
import 'package:goalkeeper/src/features/notifications/presentation/widgets/notification_action_buttons.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification.dart';
import 'package:goalkeeper/src/features/notifications/data/models/notification_action.dart';

void main() {
  group('Notification Visual Tests', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    group('ContractNotificationCard Visual Tests', () {
      testGoldens('should match golden file for contract notification card', (tester) async {
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo para um jogo',
          type: 'contract_request',
          data: {
            'contract_id': 'contract-123',
            'contractor_name': 'João Silva',
            'contractor_avatar_url': null,
            'announcement_title': 'Jogo de Futebol - Estádio Central',
            'game_date_time': DateTime(2024, 12, 25, 15, 30).toIso8601String(),
            'stadium': 'Estádio Central',
            'offered_amount': 150.0,
            'additional_notes': 'Jogo importante',
          },
          sentAt: DateTime(2024, 12, 20, 10, 0),
          createdAt: DateTime(2024, 12, 20, 10, 0),
          readAt: null,
        );

        final builder = GoldenBuilder.column()
          ..addScenario(
            'Contract Notification Card - Unread',
            ContractNotificationCard(
              notification: contractNotification,
              onAccept: () {},
              onDecline: () {},
              onTap: () {},
            ),
          )
          ..addScenario(
            'Contract Notification Card - Read',
            ContractNotificationCard(
              notification: contractNotification.copyWith(
                readAt: DateTime(2024, 12, 20, 11, 0),
              ),
              onAccept: () {},
              onDecline: () {},
              onTap: () {},
            ),
          )
          ..addScenario(
            'Contract Notification Card - No Amount',
            ContractNotificationCard(
              notification: contractNotification.copyWith(
                data: {
                  ...contractNotification.data!,
                  'offered_amount': null,
                },
              ),
              onAccept: () {},
              onDecline: () {},
              onTap: () {},
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          surfaceSize: const Size(400, 800),
        );

        await screenMatchesGolden(tester, 'contract_notification_card');
      });

      testGoldens('should match golden file for contract card with loading states', (tester) async {
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo para um jogo',
          type: 'contract_request',
          data: {
            'contract_id': 'contract-123',
            'contractor_name': 'João Silva',
            'stadium': 'Estádio Central',
            'offered_amount': 150.0,
          },
          sentAt: DateTime(2024, 12, 20, 10, 0),
          createdAt: DateTime(2024, 12, 20, 10, 0),
          readAt: null,
        );

        final builder = GoldenBuilder.column()
          ..addScenario(
            'Contract Card - Accept Loading',
            ContractNotificationCard(
              notification: contractNotification,
              onAccept: () {},
              onDecline: () {},
              onTap: () {},
              isAcceptLoading: true,
            ),
          )
          ..addScenario(
            'Contract Card - Decline Loading',
            ContractNotificationCard(
              notification: contractNotification,
              onAccept: () {},
              onDecline: () {},
              onTap: () {},
              isDeclineLoading: true,
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          surfaceSize: const Size(400, 600),
        );

        await screenMatchesGolden(tester, 'contract_notification_card_loading');
      });
    });

    group('FullLobbyNotificationCard Visual Tests', () {
      testGoldens('should match golden file for full lobby notification card', (tester) async {
        final lobbyNotification = AppNotification(
          id: 'notification-2',
          userId: 'user-123',
          title: 'Lobby Completo!',
          body: 'Seu anúncio "Jogo de Futebol" está completo (22/22)',
          type: 'full_lobby',
          data: {
            'announcement_id': 'announcement-456',
            'announcement_title': 'Jogo de Futebol - Estádio Central',
            'game_date_time': DateTime(2024, 12, 25, 15, 30).toIso8601String(),
            'stadium': 'Estádio Central',
            'participant_count': 22,
            'max_participants': 22,
          },
          sentAt: DateTime(2024, 12, 20, 10, 0),
          createdAt: DateTime(2024, 12, 20, 10, 0),
          readAt: null,
        );

        final builder = GoldenBuilder.column()
          ..addScenario(
            'Full Lobby Notification Card - Unread',
            FullLobbyNotificationCard(
              notification: lobbyNotification,
              onViewDetails: () {},
              onTap: () {},
            ),
          )
          ..addScenario(
            'Full Lobby Notification Card - Read',
            FullLobbyNotificationCard(
              notification: lobbyNotification.copyWith(
                readAt: DateTime(2024, 12, 20, 11, 0),
              ),
              onViewDetails: () {},
              onTap: () {},
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          surfaceSize: const Size(400, 500),
        );

        await screenMatchesGolden(tester, 'full_lobby_notification_card');
      });
    });

    group('NotificationActionButtons Visual Tests', () {
      testGoldens('should match golden file for notification action buttons', (tester) async {
        final contractActions = [
          NotificationAction(
            label: 'Aceitar',
            onPressed: () {},
            type: NotificationActionType.accept,
          ),
          NotificationAction(
            label: 'Recusar',
            onPressed: () {},
            type: NotificationActionType.decline,
          ),
        ];

        final viewDetailsAction = [
          NotificationAction(
            label: 'Ver Detalhes',
            onPressed: () {},
            type: NotificationActionType.viewDetails,
          ),
        ];

        final builder = GoldenBuilder.column()
          ..addScenario(
            'Contract Action Buttons - Normal',
            NotificationActionButtons(
              actions: contractActions,
              isLoading: false,
            ),
          )
          ..addScenario(
            'Contract Action Buttons - Accept Loading',
            NotificationActionButtons(
              actions: contractActions,
              isLoading: true,
              loadingActionType: NotificationActionType.accept,
            ),
          )
          ..addScenario(
            'Contract Action Buttons - Decline Loading',
            NotificationActionButtons(
              actions: contractActions,
              isLoading: true,
              loadingActionType: NotificationActionType.decline,
            ),
          )
          ..addScenario(
            'View Details Button - Normal',
            NotificationActionButtons(
              actions: viewDetailsAction,
              isLoading: false,
            ),
          )
          ..addScenario(
            'View Details Button - Loading',
            NotificationActionButtons(
              actions: viewDetailsAction,
              isLoading: true,
              loadingActionType: NotificationActionType.viewDetails,
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          surfaceSize: const Size(400, 600),
        );

        await screenMatchesGolden(tester, 'notification_action_buttons');
      });
    });

    group('Card Styling Consistency Tests', () {
      testGoldens('should match announcement card styling', (tester) async {
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: {
            'contractor_name': 'João Silva',
            'stadium': 'Estádio Central',
            'offered_amount': 150.0,
          },
          sentAt: DateTime(2024, 12, 20, 10, 0),
          createdAt: DateTime(2024, 12, 20, 10, 0),
          readAt: null,
        );

        // This test would compare notification card styling with announcement cards
        // to ensure visual consistency
        final builder = GoldenBuilder.column()
          ..addScenario(
            'Notification Card Styling',
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: ContractNotificationCard(
                notification: contractNotification,
                onAccept: () {},
                onDecline: () {},
                onTap: () {},
              ),
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          surfaceSize: const Size(400, 300),
        );

        await screenMatchesGolden(tester, 'notification_card_styling_consistency');
      });

      testGoldens('should display proper spacing and padding', (tester) async {
        final notifications = [
          AppNotification(
            id: 'notification-1',
            userId: 'user-123',
            title: 'Contract Request 1',
            body: 'First contract',
            type: 'contract_request',
            data: {'contractor_name': 'João Silva'},
            sentAt: DateTime(2024, 12, 20, 10, 0),
            createdAt: DateTime(2024, 12, 20, 10, 0),
            readAt: null,
          ),
          AppNotification(
            id: 'notification-2',
            userId: 'user-123',
            title: 'Lobby Full',
            body: 'Your lobby is full',
            type: 'full_lobby',
            data: {'announcement_title': 'Game'},
            sentAt: DateTime(2024, 12, 20, 10, 0),
            createdAt: DateTime(2024, 12, 20, 10, 0),
            readAt: null,
          ),
        ];

        final builder = GoldenBuilder.column();
        
        for (final notification in notifications) {
          if (notification.isContractRequest) {
            builder.addScenario(
              'Contract Card with Spacing',
              ContractNotificationCard(
                notification: notification,
                onAccept: () {},
                onDecline: () {},
                onTap: () {},
              ),
            );
          } else if (notification.isFullLobby) {
            builder.addScenario(
              'Lobby Card with Spacing',
              FullLobbyNotificationCard(
                notification: notification,
                onViewDetails: () {},
                onTap: () {},
              ),
            );
          }
        }

        await tester.pumpWidgetBuilder(
          builder.build(),
          surfaceSize: const Size(400, 600),
        );

        await screenMatchesGolden(tester, 'notification_spacing_padding');
      });
    });

    group('Theme Compliance Tests', () {
      testGoldens('should match app theme colors and typography', (tester) async {
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: {
            'contractor_name': 'João Silva',
            'stadium': 'Estádio Central',
            'offered_amount': 150.0,
          },
          sentAt: DateTime(2024, 12, 20, 10, 0),
          createdAt: DateTime(2024, 12, 20, 10, 0),
          readAt: null,
        );

        final builder = GoldenBuilder.column()
          ..addScenario(
            'Light Theme',
            Theme(
              data: ThemeData.light(),
              child: ContractNotificationCard(
                notification: contractNotification,
                onAccept: () {},
                onDecline: () {},
                onTap: () {},
              ),
            ),
          )
          ..addScenario(
            'Dark Theme',
            Theme(
              data: ThemeData.dark(),
              child: ContractNotificationCard(
                notification: contractNotification,
                onAccept: () {},
                onDecline: () {},
                onTap: () {},
              ),
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          surfaceSize: const Size(400, 600),
        );

        await screenMatchesGolden(tester, 'notification_theme_compliance');
      });
    });

    group('Responsive Layout Tests', () {
      testGoldens('should adapt to different screen sizes', (tester) async {
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo para um jogo no Estádio Central',
          type: 'contract_request',
          data: {
            'contractor_name': 'João Silva',
            'stadium': 'Estádio Central',
            'offered_amount': 150.0,
          },
          sentAt: DateTime(2024, 12, 20, 10, 0),
          createdAt: DateTime(2024, 12, 20, 10, 0),
          readAt: null,
        );

        // Test different screen widths
        final screenSizes = [
          const Size(320, 400), // Small phone
          const Size(375, 400), // iPhone SE
          const Size(414, 400), // iPhone Plus
          const Size(768, 400), // Tablet
        ];

        for (int i = 0; i < screenSizes.length; i++) {
          final size = screenSizes[i];
          final builder = GoldenBuilder.column()
            ..addScenario(
              'Screen Width ${size.width.toInt()}px',
              ContractNotificationCard(
                notification: contractNotification,
                onAccept: () {},
                onDecline: () {},
                onTap: () {},
              ),
            );

          await tester.pumpWidgetBuilder(
            builder.build(),
            surfaceSize: size,
          );

          await screenMatchesGolden(tester, 'notification_responsive_${size.width.toInt()}px');
        }
      });
    });

    group('Accessibility Visual Tests', () {
      testGoldens('should display proper accessibility indicators', (tester) async {
        final contractNotification = AppNotification(
          id: 'notification-1',
          userId: 'user-123',
          title: 'Nova Proposta de Contrato',
          body: 'João Silva quer contratá-lo',
          type: 'contract_request',
          data: {
            'contractor_name': 'João Silva',
            'stadium': 'Estádio Central',
          },
          sentAt: DateTime(2024, 12, 20, 10, 0),
          createdAt: DateTime(2024, 12, 20, 10, 0),
          readAt: null,
        );

        final builder = GoldenBuilder.column()
          ..addScenario(
            'High Contrast Mode',
            MediaQuery(
              data: const MediaQueryData(
                accessibleNavigation: true,
                highContrast: true,
              ),
              child: ContractNotificationCard(
                notification: contractNotification,
                onAccept: () {},
                onDecline: () {},
                onTap: () {},
              ),
            ),
          )
          ..addScenario(
            'Large Text Scale',
            MediaQuery(
              data: const MediaQueryData(
                textScaleFactor: 1.5,
              ),
              child: ContractNotificationCard(
                notification: contractNotification,
                onAccept: () {},
                onDecline: () {},
                onTap: () {},
              ),
            ),
          );

        await tester.pumpWidgetBuilder(
          builder.build(),
          surfaceSize: const Size(400, 600),
        );

        await screenMatchesGolden(tester, 'notification_accessibility');
      });
    });
  });
}