# Implementation Plan

- [x] 1. Create core guest mode infrastructure

  - Implement AuthStateProvider to detect and manage guest mode state
  - Create utility functions for guest mode detection throughout the app
  - Write unit tests for guest mode detection logic
  - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1_

- [x] 2. Implement registration prompt dialog component

  - Create RegistrationPromptDialog widget with beautiful design matching app theme
  - Implement dialog configuration system for different contexts (join match, hire goalkeeper, etc.)
  - Add proper button handling and navigation to signup screen
  - Write widget tests for dialog behavior and styling
  - _Requirements: 1.2, 1.3, 2.2, 2.3, 5.2_

- [x] 3. Create guest profile screen

  - Implement GuestProfileScreen with registration prompt design
  - Match existing app UI/UX patterns and theme
  - Add navigation button to redirect to auth/register page
  - Write widget tests for guest profile screen rendering and interactions
  - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2_

- [x] 4. Modify main navigation to support guest mode

  - Update MainScreen to detect guest mode and conditionally render appropriate screens
  - Modify app routing logic to handle guest users accessing profile screen
  - Ensure navigation bar maintains consistent styling for guest users
  - Write integration tests for guest navigation flows
  - _Requirements: 3.1, 4.1, 4.4_

-

- [x] 5. Update announcements screen for guest users

  - Modify AnnouncementsScreen to hide create announcement functionality for guests
  - Implement registration prompt when guests attempt to join matches
  - Ensure all announcement viewing functionality remains accessible to guests
  - Write tests for guest-specific announcement screen behavior
  - _Requirements: 1.1, 1.2, 1.3, 4.1, 4.4_

- [x] 6. Update map screen for guest users

  - Ensure MapScreen displays football fields and goalkeeper locations for guests
  - Implement registration prompt when guests attempt to hire goalkeepers
  - Maintain existing map visual design and functionality for guest users
  - Write tests for guest map screen interactions and hire attempt handling
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 4.1, 4.2_

- [x] 7. Implement guest mode wrapper component

  - Create GuestModeWrapper component to handle auth-required actions consistently
  - Implement action interception logic for restricted features
  - Add proper error handling and fallback behavior
  - Write unit tests for wrapper component functionality
  - _Requirements: 1.2, 2.2, 4.3, 5.1, 5.2_

- [x] 8. Update app initialization and routing

  - Modify main.dart to handle guest users in initial route determination
  - Update route generation to support guest access to allowed screens
  - Ensure proper navigation flow from registration prompts to signup screen
  - _Requirements: 1.4, 2.4, 3.3, 4.3, 5.3_

-

- [x] 9. Add guest session tracking and analytics

  - Implement GuestUserContext for tracking guest engagement
  - Add analytics for guest user behavior and registration prompt effectiveness
  - Implement smart prompt frequency management to avoid over-prompting
  - Write tests for session tracking and analytics functionality
  - At the end generate a PR.md template with a summary of all the changes made present in ./task.md
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 10. Implement comprehensive testing suite
  - Create end-to-end tests for complete guest user journeys
  - Test registration flow from various entry points (announcements, map, profile)
  - Verify UI consistency and proper error handling across all guest features
  - Test navigation between guest and authenticated modes
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4_
