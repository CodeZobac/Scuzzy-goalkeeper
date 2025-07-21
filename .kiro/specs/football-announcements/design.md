# Design Document

## Overview

The Football Announcements feature will be implemented as a comprehensive UI system that matches the provided design mockups exactly. The feature consists of two main screens: a "Recruitment" list screen and a detailed announcement view. The design features a vibrant green theme with rounded cards, elegant typography, and a modern mobile-first approach.

**Key Design Elements from Mockup:**

- **Left Screen**: Recruitment list with green header, white announcement cards, organizer profiles with ratings, and bottom navigation
- **Right Screen**: Detailed announcement view with organizer header, white content card, participant avatars, join button, and green stadium section

The system will integrate with the existing Supabase backend and follow the established Flutter architecture patterns used in the project, including Provider for state management and a clean architecture approach with repositories, controllers, and presentation layers.

## Architecture

### High-Level Architecture

```
Presentation Layer (UI)
├── Screens (AnnouncementsScreen, AnnouncementDetailScreen)
├── Widgets (Custom UI components)
└── Controllers (State management with Provider)

Domain Layer
├── Models (Enhanced Announcement model)
└── Repository Interfaces

Data Layer
├── Repository Implementations
└── Supabase Integration
```

### State Management

- **Provider Pattern**: Continue using the existing Provider pattern for state management
- **AnnouncementController**: Enhanced to handle participant management and UI state
- **Local State**: Use StatefulWidget for component-specific state like loading states

### Navigation

- **Named Routes**: Integrate with existing MaterialApp routing
- **Screen Transitions**: Use standard Flutter navigation with custom transitions if needed

## Components and Interfaces

### 1. Enhanced Data Models

#### Announcement Model Extensions

```dart
class Announcement {
  // Existing fields...
  final String? organizerName;
  final String? organizerAvatarUrl;
  final double? organizerRating;
  final String? stadiumImageUrl;
  final double? distanceKm;
  final int participantCount;
  final int maxParticipants;
  final List<AnnouncementParticipant> participants;
}

class AnnouncementParticipant {
  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime joinedAt;
}
```

### 2. Screen Components

#### AnnouncementsListScreen

- **Header Section**: Green gradient background with date, title, and filter icon
- **Announcement Cards**: Custom cards matching the design with:
  - Stadium image and details
  - Organizer information with rating
  - Game details (time, date, price)
  - Participant preview
- **Bottom Navigation**: Integration with existing navigation

#### AnnouncementDetailScreen

- **Header**: Organizer profile with back navigation
- **Content Card**: White rounded card containing:
  - Title and description
  - Game details with icons
  - Participant section with avatars
  - Join/Leave button
- **Stadium Section**: Green background with stadium image and map integration

### 3. Custom Widgets

#### AnnouncementCard

```dart
class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;

  // Custom styling to match design
  // Green gradient backgrounds
  // Rounded corners and shadows
  // Organizer rating display
}
```

#### ParticipantAvatarRow

```dart
class ParticipantAvatarRow extends StatelessWidget {
  final List<AnnouncementParticipant> participants;
  final int maxVisible;

  // Circular avatars with overlap
  // "+X" indicator for additional participants
}
```

#### GameDetailsRow

```dart
class GameDetailsRow extends StatelessWidget {
  final DateTime date;
  final TimeOfDay time;
  final double? price;

  // Icons with labels for time, date, price
  // Consistent styling with design
}
```

#### StadiumCard

```dart
class StadiumCard extends StatelessWidget {
  final String stadiumName;
  final String? imageUrl;
  final double? distance;
  final VoidCallback onMapTap;

  // Green background with stadium image
  // Distance and map button
}
```

### 4. Enhanced Repository Interface

```dart
abstract class AnnouncementRepository {
  // Existing methods...
  Future<Announcement> getAnnouncementById(int id);
  Future<List<AnnouncementParticipant>> getParticipants(int announcementId);
  Future<bool> isUserParticipant(int announcementId, String userId);
  Future<Map<String, dynamic>> getOrganizerInfo(String userId);
  Future<Map<String, dynamic>> getStadiumInfo(String stadiumName);
}
```

## Data Models

### Database Schema Integration

The implementation will work with the existing `announcements` and `announcement_participants` tables:

```sql
-- announcements table (existing)
CREATE TABLE announcements (
  id BIGINT PRIMARY KEY,
  created_by UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  description TEXT,
  date DATE NOT NULL,
  time TIME NOT NULL,
  price DECIMAL,
  stadium TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- announcement_participants table (existing)
CREATE TABLE announcement_participants (
  id BIGINT PRIMARY KEY,
  announcement_id BIGINT REFERENCES announcements(id),
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Additional Data Requirements

For the UI to match the design, we'll need to join with the `users` table to get:

- Organizer name and profile information
- Participant names and avatars
- User ratings (if available in user stats)

## Error Handling

### Network Errors

- **Loading States**: Show skeleton loaders during data fetching
- **Error States**: Display user-friendly error messages with retry options
- **Offline Handling**: Cache recent announcements for offline viewing

### User Input Validation

- **Form Validation**: Validate announcement creation forms
- **Participation Limits**: Prevent joining when announcement is full
- **Authentication**: Handle unauthenticated users appropriately

### UI Error States

- **Empty States**: Show appropriate messages when no announcements exist
- **Image Loading**: Handle failed image loads with placeholder images
- **Network Timeouts**: Provide retry mechanisms for failed requests

## Testing Strategy

### Unit Tests

- **Model Tests**: Test Announcement and AnnouncementParticipant models
- **Repository Tests**: Mock Supabase client and test data operations
- **Controller Tests**: Test state management and business logic

### Widget Tests

- **Custom Widgets**: Test AnnouncementCard, ParticipantAvatarRow, etc.
- **Screen Tests**: Test screen rendering and user interactions
- **Navigation Tests**: Test screen transitions and routing

### Integration Tests

- **End-to-End Flows**: Test complete user journeys
- **Database Integration**: Test with real Supabase instance
- **Authentication Flow**: Test with authenticated and unauthenticated users

### Visual Tests

- **Golden Tests**: Capture widget screenshots for visual regression testing
- **Responsive Tests**: Test on different screen sizes
- **Theme Tests**: Ensure consistent styling across components

## UI Implementation Details

### Design System

**Exact Visual Specifications from Mockup:**

- **Colors**:

  - Primary Green: #4CAF50 (vibrant green from header and stadium section)
  - Secondary Green: #45A049 (darker green for gradients)
  - Orange Accent: #FF9800 (for join button and +2 indicator)
  - Background: #F8F9FA (light gray background)
  - Card Background: #FFFFFF (pure white cards)
  - Text Primary: #2C2C2C (dark text)
  - Text Secondary: #757575 (gray text for subtitles)
  - Text Light: #FFFFFF (white text on green backgrounds)

- **Typography**:

  - Header Title: Bold, 28px, White ("Recruitment")
  - Card Title: Bold, 18px, Dark (#2C2C2C)
  - Organizer Name: Medium, 16px, Dark
  - Description: Regular, 14px, Gray (#757575)
  - Details: Regular, 12px, Gray
  - Stadium Name: Bold, 20px, White

- **Layout Specifications**:
  - Screen padding: 16px horizontal
  - Card margins: 12px vertical
  - Card padding: 16px
  - Card border radius: 16px
  - Avatar size: 40px (organizers), 32px (participants)
  - Button height: 48px
  - Icon size: 20px for details, 24px for navigation

### Detailed Screen Analysis

#### Left Screen - Recruitment List

- **Header**: Green gradient background with the date atualized date of the current day, example "Today, 01 April" subtitle, "Recruitment" title, and filter icon
- **Cards**: White rounded cards with:
  - Stadium image with "+2" overlay indicator
  - Stadium name and distance
  - Description text
  - Time/Date/Price row with icons
  - Organizer profile with avatar, name, star rating, and "Solo" badge
- **Bottom Navigation**: Green active tab with "25" indicator

#### Right Screen - Announcement Detail

- **Header**: White background with organizer profile (Alex Pesenka) and back arrow
- **Content**: White card with:
  - Title "Friday football with my friends"
  - Description paragraph
  - Time/Date/Price icons row
  - Participants section showing "(11/22)" count
  - Avatar row with "+4" indicator and "Members" label
  - Orange "Join Event" button
- **Stadium Section**: Green background with:
  - "Minsk City Stadium" title
  - Distance "2 km away"
  - Stadium photo with "+24" photo count
  - "On the map" button with arrow

### Animations

- **Card Interactions**: Subtle scale animation on tap
- **Loading States**: Shimmer effect for skeleton loaders
- **Screen Transitions**: Smooth slide transitions between screens
- **Button States**: Ripple effects and state changes

### Responsive Design

- **Mobile First**: Optimize for mobile screens
- **Tablet Support**: Adapt layout for larger screens
- **Safe Areas**: Handle notches and system UI properly
- **Keyboard Handling**: Adjust UI when keyboard is visible

### Accessibility

- **Semantic Labels**: Proper accessibility labels for screen readers
- **Color Contrast**: Ensure sufficient contrast ratios
- **Touch Targets**: Minimum 44px touch targets
- **Focus Management**: Proper focus handling for navigation
