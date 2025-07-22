# Implementation Plan

- [x] 1. Extend data models for new notification types

  - Enhance the existing AppNotification model with new helper methods for contract and full lobby notifications
  - Create ContractNotificationData and FullLobbyNotificationData classes for structured data handling
  - Add notification category enum and type checking methods
  - Write unit tests for enhanced model functionality
  - _Requirements: 1.1, 2.1, 3.1, 8.1_

- [x] 2. Create database schema extensions

- [x] 2. Create database schema extensions

  - Add new columns to notifications table (category, requires_action, action_taken_at, expires_at)
  - Create goalkeeper_contracts table for contract management
  - Set up database indexes for performance optimization
  - Enable Supabase real-time subscriptions for notifications and contracts tables
  - Use Supabase MCP
  - _Requirements: 1.1, 2.1, 4.2, 4.3_

- [x] 3. Implement ContractNotificationCard widget

  - Create widget matching announcement card styling with white background and rounded corners
  - Add contractor profile section with avatar, name, and contract details
  - Implement game details row with date, time, and location icons
  - Add offered amount display with proper currency formatting
  - Create Accept and Decline action buttons with loading states
  - _Requirements: 1.2, 1.3, 3.2, 3.3, 4.1_

- [x] 4. Implement FullLobbyNotificationCard widget

- [x] 4. Implement FullLobbyNotificationCard widget

  - Create widget with same card styling as announcements
  - Add celebration icon and "lobby full" indicator
  - Display participant count in "(22/22)" format
  - Include game details section matching a

nnouncement format

- Add "View Details" action button with proper styling
- _Requirements: 2.2, 2.3, 3.2, 3.3, 4.4_

- [x] 5. Create NotificationActionButtons component

  - Build reusable action button component with consistent styling
  - Implement Accept button with green gradient (#4CAF50 to #45A049)
  - Implement Decline button with red gradient (#FF6B6B to #E94560)
  - Add loading states with spinners and disabled states
  - Include proper touch targets and accessibility labels
  - _Requirements: 4.1, 4.2, 4.3, 4.5_

- [x] 6. Enhance NotificationRepository with new methods

  - Add createContractNotification method for goalkeeper contract requests
  - Add createFullLobbyNotification method for full announcement notifications
  - Implement handleContractResponse method for accept/decline actions
  - Add getNotificationsByCategory method for filtered notifications
  - Create watchNotifications stream for real-time updates
  - _Requirements: 1.1, 2.1, 4.2, 4.3, 8.1_

- [x] 7. Implement contract management system

  - Create contract creation logic when players request goalkeepers
  - Add contract expiration handling (24-hour default)
  - Implement accept/decline response processing
  - Add contract status tracking and updates
  - Create notification cleanup for expired contracts
  - _Requirements: 1.1, 1.4, 4.2, 4.3_

- [x] 8. Add full lobby detection system

-

- [x] 8. Add full lobby detection system

  - Monitor announcement participant count changes
  - Trigger full lobby notifications when capacity is reached
  - Implement notification delivery within 30 seconds requirement
  - Add duplicate notification prevention

  - Create announcement status tracking

  - _Requirements: 2.1, 2.2, 2.5_

- [x] 9. Enhance NotificationsScreen with categorization

  - Add notification category tabs or sections
  - Implement category filtering and display logic

  - Update card rendering to use new notification card widgets

  - Add category-specific empty states

  - Implement real-time notification updates
  - _Requirements: 3.1, 3.2, 5.1, 8.1, 8.2_

- [x] 10. Implement notification action handling

  - Add contract accept/decline action handlers in NotificationController
  - Implement navigation to contract details and announcement details

  - Add action feedback with success/error messages

  - Create loading states during action processing
  - Add action confirmation dialogs where appropriate
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 11. Enhance push notification system

- Extend NotificationService to handle new notification types
- Add contract request push notification formatting
- Add full lobby push notification formatting

- Implement notification tap handling for new types
- Add notification data parsing for navigation

- _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 12. Add notification preferences system

  - Create notification settings screen or section

  - Add toggle switches for contract and full lobby notifications
  - Implement preference storage in user profile or settings table
  - Add preference checking before sending notifications
  - Create preference sync across devices
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 13. Implement real-time notification updates

  - Set up Supabase real-time subscriptions for notifications
  - Add real-time notification insertion and updates
  - Implement notification status synchronization
  - Add connection handling and reconnection logic

  - Create real-time notification count updates
  - _Requirements: 5.3, 5.5, 8.3_

- [x] 14. Add notification status management

  - Implement automatic read status updates when notifications are viewed
  - Add unread notification indicators and badges
  - Create visual distinction between read and unread notifications
  - Add "mark all as read" functionality for categories
  - Implement notification archiving after 30 days
  - _Requirements: 5.1, 5.2, 5.4, 8.4_

-

- [x] 15. Create notification history and pagination

  - Implement pagination for large notification lists
  - Add infinite scroll or load more functionality
  - Create notification history with proper timestamp formatting
  - Add search and filter capabilities
  - Implement notification deletion and cleanup
  - _Requirements: 8.2, 8.3, 8.5_

-

- [x] 16. Add comprehensive error handling

  - Implement error handling for notification creation failures
  - Add retry mechanisms for failed push notifications
  - Create fallback handling for network issues
  - Add error states for action processing failures
  - Implement graceful degradation for real-time connection issues

  - _Requirements: 4.5, 6.5_

- [x] 17. Write comprehensive tests

  - Create unit tests for enhanced notification models and data classes
  - Write widget tests for ContractNotificationCard and FullLobbyNotificationCard
  - Add integration tests for contract flow and full lobby detection
  - Create tests for notification action handling and real-time updates
  - Add visual regression tests for card styling consistency
  - _Requirements: All requirements validation_

- [ ] 18. Integrate with existing app navigation

  - Update main app routing to handle new notification navigation
  - Add deep linking support for notification actions
  - Integrate with existing bottom navigation and screen flow
  - Test navigation from push notifications to appropriate screens
  - Ensure proper back navigation and state management
  - _Requirements: 1.5, 2.4, 4.4, 6.4_
