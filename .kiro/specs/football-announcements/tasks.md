# Implementation Plan

- [x] 1. Set up enhanced data models and repository interfaces

  - Extend the existing Announcement model to include organizer info, participant data, and stadium details
  - Add AnnouncementParticipant model for participant management
  - Update AnnouncementRepository interface with new methods for participants and organizer info
  - _Requirements: 1.2, 2.4, 6.1, 7.1_

- [x] 2. Implement enhanced repository with Supabase integration

  - Update AnnouncementRepositoryImpl to fetch organizer information from users table
  - Implement participant management methods (join, leave, get participants)
  - Add methods to fetch user ratings and profile information
  - Create database queries to join announcements with user data
  - _Requirements: 3.2, 3.3, 6.1, 7.2_

- [x] 3. Create custom UI components for announcement cards

  - Build AnnouncementCard widget matching the exact design specifications
  - Implement stadium image display with overlay indicators (+2, +24)
  - Create organizer profile section with avatar, name, rating stars, and "Solo" badge
  - Add game details row with time, date, and price icons
  - _Requirements: 1.2, 1.3, 7.1, 7.3_

- [x] 4. Implement participant avatar components

  - Create ParticipantAvatarRow widget with overlapping circular avatars
  - Implement "+X" indicator for additional participants beyond visible limit
  - Add "Members" label and participant count display "(11/22)"
  - Handle empty participant states appropriately
  - _Requirements: 6.1, 6.2, 6.3, 6.5_

- [x] 5. Build the Recruitment list screen UI

  - Create AnnouncementsScreen with green gradient header
  - Implement "Today, 01 April" date display and "Recruitment" title
  - Add filter icon in header matching design
  - Create scrollable list of announcement cards with proper spacing
  - Integrate with existing bottom navigation showing "25" indicator
  - _Requirements: 1.1, 1.2, 1.4, 1.5_

- [x] 6. Implement announcement detail screen UI

  - Create AnnouncementDetailScreen with organizer header
  - Build white content card with title, description, and game details
  - Implement time/date/price icons row matching design exactly
  - Add participant section with avatars and count display
  - Create orange "Join Event" button with proper styling
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 7. Build stadium section with green background

  - Create StadiumCard widget with green gradient background
  - Implement stadium image display with "+24" photo count overlay
  - Add stadium name, distance, and "On the map" button
  - Style with exact colors and layout from design mockup

  - _Requirements: 2.6, 5.1, 5.2, 5.3, 5.5_

- [x] 8. Implement join/leave functionality

  - Add join event logic to AnnouncementController
  - Handle participant limit validation and full announcement states
  - Implement leave event functionality for existing participants
  - Update UI state when user joins or leaves an announcement
  - Show appropriate button states (Join Event vs Leave Event)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 9. Add navigation and screen transitions

  - Implement navigation from announcement cards to detail screen
  - Add back navigation from detail screen to list
  - Integrate with existing app routing system
  - Handle navigation to map screen when "On the map" is tapped

- _Requirements: 2.1, 5.4_
- [x] 10. Implement loading states and error handling

- [-] 10. Implement loading states and error handling

  - Add skeleton loaders for announcement cards during data fetching
  - Create empty state UI when no announcements are available
  - Implement error states with retry functionality
  - Handle image loading failures with placeholder images
  - Add loading indicators for join/leave actions
  - _Requirements: 1.5, 3.3, 3.4_

- [x] 11. Add create announcement functionality

  - Build announcement creation form with title, description, date, time, price, and stadium fields
  - Implement form validation for required fields
  - Add form submission logic to save announcements to database
  - Set creator as organizer when announcement is created
  - Navigate back to list and refresh data after creation
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 12. Integrate with existing app architecture

  - Update main.dart to include new routes for announcement screens
  - Ensure AnnouncementController is properly provided in widget tree
  - Test integration with existing authentication and navigation systems
  - Verify proper state management across screen transitions
  - _Requirements: All requirements integration_
