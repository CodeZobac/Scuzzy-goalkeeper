# Full Lobby Detection System

## Overview

The Full Lobby Detection System monitors announcement participant counts and automatically sends notifications to announcement creators when their announcements reach full capacity (maximum participants).

## Key Features

### 1. Real-time Monitoring

- Monitors `announcement_participants` table changes via Supabase real-time subscriptions
- Detects when participants join or leave announcements
- Triggers capacity checks within seconds of participant changes

### 2. Duplicate Prevention

- Tracks processed announcements to prevent duplicate notifications
- Maintains in-memory cache of full lobby notifications already sent
- Loads existing full lobby notifications on service initialization

### 3. Notification Delivery (≤30 seconds)

- Real-time detection via Supabase subscriptions (immediate)
- Periodic fallback checks every 30 seconds
- Ensures notification delivery within the 30-second requirement

### 4. Announcement Status Tracking

- Tracks announcement status: `active`, `full`, `expired`
- Provides statistics on monitored announcements
- Supports manual capacity checks for testing

## Architecture

```
FullLobbyDetectionService
├── Real-time Monitoring (Primary)
│   ├── Supabase real-time subscription
│   ├── PostgresChangeEvent.insert handler
│   └── PostgresChangeEvent.delete handler
├── Periodic Checks (Fallback)
│   ├── Timer-based checks every 30 seconds
│   └── Processes all active announcements
├── Duplicate Prevention
│   ├── In-memory processed announcements cache
│   └── Database lookup on initialization
└── Notification Creation
    ├── FullLobbyNotificationData creation
    ├── Database notification insertion
    └── Push notification sending
```

## Usage

### Initialization

```dart
final notificationRepository = NotificationRepository();
final fullLobbyService = FullLobbyDetectionService(
  notificationRepository,
  Supabase.instance.client
);

await fullLobbyService.initialize();
```

### Integration with NotificationServiceManager

```dart
// Automatic initialization when user signs in
await NotificationServiceManager.instance.onUserSignIn(userId);

// Manual capacity check
await NotificationServiceManager.instance.checkAnnouncementFullLobby(announcementId);

// Get statistics
final stats = NotificationServiceManager.instance.getFullLobbyStatistics();
```

## Database Schema Requirements

### Notifications Table Extensions

```sql
ALTER TABLE notifications
ADD COLUMN category VARCHAR(50) DEFAULT 'general',
ADD COLUMN requires_action BOOLEAN DEFAULT false,
ADD COLUMN action_taken_at TIMESTAMP,
ADD COLUMN expires_at TIMESTAMP;
```

### Real-time Subscriptions

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE announcement_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
```

## Notification Data Structure

### FullLobbyNotificationData

```dart
{
  "announcement_id": "123",
  "announcement_title": "Sunday Football Game",
  "game_date_time": "2024-01-15T18:00:00.000Z",
  "stadium": "Central Stadium",
  "participant_count": 22,
  "max_participants": 22
}
```

### Database Notification Record

```dart
{
  "user_id": "creator-user-id",
  "title": "Lobby Completo!",
  "body": "Seu anúncio \"Sunday Football Game\" está completo (22/22)",
  "type": "full_lobby",
  "category": "full_lobbies",
  "data": { /* FullLobbyNotificationData */ },
  "requires_action": false,
  "sent_at": "2024-01-15T18:00:00.000Z",
  "created_at": "2024-01-15T18:00:00.000Z"
}
```

## Error Handling

### Database Errors

- Graceful handling of connection issues
- Retry mechanisms for failed queries
- Fallback to periodic checks if real-time fails

### Notification Creation Errors

- Error logging for failed notification creation
- Continues monitoring even if individual notifications fail
- Maintains service availability

### Service Lifecycle

- Proper resource cleanup on disposal
- Handles multiple initialization calls
- Safe disposal of real-time subscriptions and timers

## Performance Considerations

### Memory Usage

- In-memory cache of processed announcements
- Periodic cleanup of old announcement statuses
- Efficient data structures for tracking

### Database Load

- Optimized queries with proper indexes
- Batch processing for periodic checks
- Real-time subscriptions reduce polling load

### Network Efficiency

- Real-time subscriptions minimize network calls
- Efficient data structures in notifications
- Push notification batching where possible

## Testing

### Unit Tests

- Core logic testing with mocked dependencies
- Announcement status tracking verification
- Statistics and disposal testing

### Integration Tests

- End-to-end full lobby detection flow
- Real database interaction testing
- Duplicate prevention verification

### Manual Testing

```dart
// Check specific announcement
await fullLobbyService.checkAnnouncement(announcementId);

// Get service statistics
final stats = fullLobbyService.getStatistics();
print('Processed full lobbies: ${stats['processed_full_lobbies']}');

// Check if announcement was processed
final isProcessed = fullLobbyService.isAnnouncementProcessed(announcementId);
```

## Requirements Compliance

### Requirement 2.1: Full Lobby Detection

✅ Monitors announcement participant count changes
✅ Triggers notifications when capacity is reached

### Requirement 2.2: Notification Content

✅ Shows announcement title and participant count
✅ Includes game date and stadium information

### Requirement 2.5: Delivery Time

✅ Real-time detection (immediate)
✅ Periodic fallback ensures ≤30 second delivery
✅ Duplicate prevention system

## Future Enhancements

### Scalability

- Redis cache for distributed systems
- Message queue for notification processing
- Horizontal scaling support

### Advanced Features

- Configurable notification thresholds
- Multiple notification types (75%, 90%, 100% full)
- Analytics and reporting

### Monitoring

- Service health checks
- Performance metrics
- Error rate monitoring
