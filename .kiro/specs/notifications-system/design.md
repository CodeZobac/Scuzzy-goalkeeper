# Design Document

## Overview

The Enhanced Notifications System will extend the existing notification infrastructure to provide targeted notifications for goalkeeper contracts and full lobby announcements. The design follows the established visual patterns from the announcements feature, using the same card-based layout, color schemes, and typography while introducing new notification types and enhanced interaction capabilities.

**Key Design Principles:**

- **Visual Consistency**: Match the exact styling of announcement cards with white backgrounds, rounded corners, and subtle shadows
- **Enhanced Interactivity**: Add action buttons for accepting/declining contracts and viewing details
- **Real-time Updates**: Leverage existing Firebase/Supabase integration for instant notifications
- **Categorization**: Group notifications by type with clear visual indicators
- **Responsive Design**: Maintain the mobile-first approach with proper spacing and touch targets

The system builds upon the existing `NotificationService`, `AppNotification` model, and notification screen while adding new notification types, enhanced UI components, and improved user interactions.

## Architecture

### High-Level Architecture

```
Presentation Layer
├── Enhanced NotificationsScreen (existing, enhanced)
├── New Notification Widgets
│   ├── ContractNotificationCard
│   ├── FullLobbyNotificationCard
│   └── NotificationActionButtons
└── Enhanced NotificationController

Domain Layer
├── Enhanced AppNotification Model
├── New Notification Types (contract, full_lobby)
└── Notification Action Handlers

Data Layer
├── Enhanced NotificationRepository
├── Contract Management Integration
└── Announcement Integration

Services Layer
├── Enhanced NotificationService (existing)
├── Push Notification Handlers
└── Real-time Event Listeners
```

### Integration Points

- **Existing Announcements System**: Listen for participant count changes
- **Goalkeeper Booking System**: Handle contract creation and responses
- **Firebase Messaging**: Enhanced push notification handling
- **Supabase Real-time**: Live notification updates

## Components and Interfaces

### 1. Enhanced Data Models

#### Extended AppNotification Model

```dart
class AppNotification {
  // Existing fields...
  final String type; // 'contract_request', 'full_lobby', 'booking_request'
  final Map<String, dynamic>? data;

  // New helper methods
  bool get isContractRequest => type == 'contract_request';
  bool get isFullLobby => type == 'full_lobby';
  bool get requiresAction => isContractRequest;

  // Enhanced data accessors
  String? get contractId => data?['contract_id'];
  String? get announcementId => data?['announcement_id'];
  String? get contractorName => data?['contractor_name'];
  double? get offeredAmount => data?['offered_amount'];
  String? get gameLocation => data?['game_location'];
  DateTime? get gameDateTime => data?['game_date_time'] != null
    ? DateTime.parse(data!['game_date_time']) : null;
}
```

#### New Contract Notification Data Structure

```dart
class ContractNotificationData {
  final String contractId;
  final String contractorId;
  final String contractorName;
  final String? contractorAvatarUrl;
  final String announcementId;
  final String announcementTitle;
  final DateTime gameDateTime;
  final String stadium;
  final double? offeredAmount;
  final String? additionalNotes;
}
```

#### New Full Lobby Notification Data Structure

```dart
class FullLobbyNotificationData {
  final String announcementId;
  final String announcementTitle;
  final DateTime gameDateTime;
  final String stadium;
  final int participantCount;
  final int maxParticipants;
}
```

### 2. Enhanced UI Components

#### ContractNotificationCard

```dart
class ContractNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;

  // Visual specifications matching announcement cards:
  // - White background with rounded corners (20px radius)
  // - Subtle shadow with 0.1 opacity
  // - 16px padding throughout
  // - Contractor profile section with avatar and name
  // - Game details with icons (time, date, location)
  // - Offered amount display with currency formatting
  // - Action buttons: Accept (green) and Decline (red)
}
```

#### FullLobbyNotificationCard

```dart
class FullLobbyNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onViewDetails;
  final VoidCallback onTap;

  // Visual specifications:
  // - Same card styling as announcements
  // - Celebration icon or full lobby indicator
  // - Participant count display "(22/22)"
  // - Game details section
  // - Single "View Details" action button
}
```

#### NotificationActionButtons

```dart
class NotificationActionButtons extends StatelessWidget {
  final List<NotificationAction> actions;
  final bool isLoading;

  // Consistent button styling:
  // - Height: 40px
  // - Border radius: 12px
  // - Accept: Green gradient (#4CAF50 to #45A049)
  // - Decline: Red gradient (#FF6B6B to #E94560)
  // - View Details: Blue gradient matching app theme
  // - Loading states with spinners
}
```

### 3. Enhanced Screen Components

#### Enhanced NotificationsScreen

The existing screen will be enhanced with:

- **Categorized Sections**: Group notifications by type
- **Enhanced Card Styling**: Match announcement card visual design
- **Action Handling**: Support for accept/decline actions
- **Real-time Updates**: Live notification updates via Supabase
- **Improved Empty States**: Category-specific empty state messages

#### New Notification Categories

```dart
enum NotificationCategory {
  contracts('Contratos', Icons.handshake),
  fullLobbies('Lobbies Completos', Icons.group),
  general('Geral', Icons.notifications);

  const NotificationCategory(this.title, this.icon);
  final String title;
  final IconData icon;
}
```

### 4. Enhanced Repository Interface

```dart
abstract class NotificationRepository {
  // Existing methods...

  // New methods for enhanced functionality
  Future<void> createContractNotification({
    required String goalkeeperUserId,
    required String contractorUserId,
    required String announcementId,
    required ContractNotificationData data,
  });

  Future<void> createFullLobbyNotification({
    required String creatorUserId,
    required String announcementId,
    required FullLobbyNotificationData data,
  });

  Future<void> handleContractResponse({
    required String notificationId,
    required String contractId,
    required bool accepted,
  });

  Future<List<AppNotification>> getNotificationsByCategory(
    String userId,
    NotificationCategory category,
  );

  Stream<List<AppNotification>> watchNotifications(String userId);
}
```

## Data Models

### Database Schema Extensions

#### Enhanced notifications table

```sql
-- Extend existing notifications table
ALTER TABLE notifications
ADD COLUMN category VARCHAR(50) DEFAULT 'general',
ADD COLUMN requires_action BOOLEAN DEFAULT false,
ADD COLUMN action_taken_at TIMESTAMP,
ADD COLUMN expires_at TIMESTAMP;

-- Create index for better performance
CREATE INDEX idx_notifications_category_user ON notifications(user_id, category, created_at DESC);
CREATE INDEX idx_notifications_requires_action ON notifications(user_id, requires_action, created_at DESC);
```

#### New contracts table

```sql
CREATE TABLE goalkeeper_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id BIGINT REFERENCES announcements(id),
  goalkeeper_user_id UUID REFERENCES auth.users(id),
  contractor_user_id UUID REFERENCES auth.users(id),
  offered_amount DECIMAL(10,2),
  status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, declined, expired
  additional_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  responded_at TIMESTAMP,
  expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '24 hours')
);

-- Create indexes
CREATE INDEX idx_contracts_goalkeeper ON goalkeeper_contracts(goalkeeper_user_id, status);
CREATE INDEX idx_contracts_announcement ON goalkeeper_contracts(announcement_id, status);
```

### Real-time Subscriptions

```sql
-- Enable real-time for notifications
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE goalkeeper_contracts;
```

## Error Handling

### Notification Delivery Failures

- **FCM Token Issues**: Graceful handling of invalid or expired tokens
- **Network Failures**: Retry mechanism with exponential backoff
- **Database Errors**: Fallback to local storage for critical notifications
- **Permission Denied**: Clear user messaging about notification permissions

### Action Processing Errors

- **Contract Expiration**: Handle expired contract notifications gracefully
- **Concurrent Actions**: Prevent duplicate contract responses
- **Network Timeouts**: Show loading states and retry options
- **Invalid Data**: Validate notification data before processing

### UI Error States

- **Loading States**: Skeleton loaders matching announcement card layout
- **Network Errors**: Retry buttons with clear error messages
- **Empty Categories**: Category-specific empty state illustrations
- **Action Failures**: Toast messages for failed actions with retry options

## Testing Strategy

### Unit Tests

- **Enhanced Models**: Test new notification types and data parsing
- **Repository Methods**: Mock Supabase client for contract and notification operations
- **Controller Logic**: Test notification categorization and action handling
- **Utility Functions**: Test time formatting, data validation, and helper methods

### Widget Tests

- **ContractNotificationCard**: Test rendering with different contract data
- **FullLobbyNotificationCard**: Test participant count display and actions
- **NotificationActionButtons**: Test button states and loading indicators
- **Enhanced NotificationsScreen**: Test categorization and filtering

### Integration Tests

- **Real-time Updates**: Test Supabase real-time notification delivery
- **Push Notifications**: Test FCM integration with new notification types
- **Contract Flow**: Test complete contract request/response cycle
- **Full Lobby Detection**: Test announcement capacity monitoring

### Visual Tests

- **Card Consistency**: Golden tests comparing notification cards to announcement cards
- **Theme Compliance**: Verify color schemes and typography match app theme
- **Responsive Layout**: Test on different screen sizes and orientations
- **Animation Smoothness**: Test card animations and state transitions

## UI Implementation Details

### Visual Design Specifications

**Exact Styling to Match Announcements:**

- **Card Container**:

  - Background: `Colors.white`
  - Border radius: `20px`
  - Shadow: `Colors.black.withOpacity(0.1)`, blur: `8px`, offset: `(0, 2)`
  - Margin: `vertical: 12px, horizontal: 16px`
  - Padding: `16px`

- **Typography** (matching AppTheme):

  - Card titles: `fontSize: 16, fontWeight: FontWeight.bold, color: #2C2C2C`
  - Body text: `fontSize: 14, color: #2C2C2C, height: 1.4`
  - Secondary text: `fontSize: 12, color: #757575`
  - Action button text: `fontSize: 14, fontWeight: FontWeight.w600`

- **Color Scheme**:
  - Accept button: Green gradient `#4CAF50` to `#45A049`
  - Decline button: Red gradient `#FF6B6B` to `#E94560`
  - View Details button: App accent color `#00A85A`
  - Unread indicator: `#FF9800` (orange accent)

### Enhanced Notification Categories

#### Contract Request Cards

- **Header Section**: Contractor profile with avatar, name, and "wants to hire you" text
- **Game Details**: Date, time, location with consistent icons from GameDetailsRow
- **Offer Section**: Highlighted offered amount with currency symbol
- **Action Section**: Accept and Decline buttons with loading states
- **Additional Info**: Contract expiration time and any special notes

#### Full Lobby Cards

- **Header Section**: Announcement title with "is now full!" indicator
- **Participant Display**: "(22/22)" count with celebration icon
- **Game Details**: Date, time, location matching announcement format
- **Action Section**: Single "View Details" button to navigate to announcement
- **Success Indicator**: Green checkmark or completion badge

### Animation and Interactions

- **Card Entry**: Staggered fade-in animation (200ms + index \* 100ms)
- **Button Press**: Ripple effect with color feedback
- **Action Processing**: Button transforms to loading spinner
- **Success/Error**: Brief color flash and optional haptic feedback
- **Real-time Updates**: Smooth insertion/removal of notification cards

### Accessibility Features

- **Semantic Labels**: Clear descriptions for screen readers
- **Touch Targets**: Minimum 44px for all interactive elements
- **Color Contrast**: Ensure sufficient contrast ratios for all text
- **Focus Management**: Proper focus handling for keyboard navigation
- **Haptic Feedback**: Subtle vibration for important actions

### Responsive Considerations

- **Mobile First**: Optimized for mobile screens (375px+)
- **Tablet Support**: Proper spacing and layout for larger screens
- **Safe Areas**: Handle notches and system UI appropriately
- **Keyboard Handling**: Adjust layout when keyboard is visible
- **Orientation**: Support both portrait and landscape modes

## Real-time Integration

### Supabase Real-time Setup

```dart
class NotificationRealtimeService {
  late RealtimeChannel _notificationChannel;

  void subscribeToNotifications(String userId) {
    _notificationChannel = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: _handleNewNotification,
        )
        .subscribe();
  }
}
```

### Push Notification Enhancement

```dart
class EnhancedNotificationService extends NotificationService {
  Future<void> sendContractNotification({
    required String goalkeeperUserId,
    required ContractNotificationData data,
  }) async {
    // Create database notification
    await _createDatabaseNotification(goalkeeperUserId, data);

    // Send push notification
    await _sendPushNotification(
      userId: goalkeeperUserId,
      title: 'Nova Proposta de Contrato',
      body: '${data.contractorName} quer contratá-lo para um jogo',
      data: data.toMap(),
    );
  }
}
```

This design ensures the notifications system seamlessly integrates with the existing app architecture while providing enhanced functionality and maintaining visual consistency with the announcements feature.
