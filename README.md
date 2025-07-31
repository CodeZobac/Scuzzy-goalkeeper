# Goalkeeper-Finder

## Project Overview

Goalkeeper-Finder is a Flutter application designed to connect amateur football players and teams with goalkeepers available for hire on a per-game basis. The platform functions similarly to an "Uber for goalkeepers," allowing players to find and book a goalkeeper based on location, availability, and cost.

## Key Features

- **Search and Filtering:** Players can search for goalkeepers and filter them by city.
- **User Profiles:** The application supports two types of users:
    - **Players:** Can search, book, and rate goalkeepers.
    - **Goalkeepers:** Can create a detailed profile, set their price per game, manage their availability, and receive booking notifications.
- **Availability Management:** Goalkeepers can specify the dates and times they are available to play.
- **Booking System:** Players can select a goalkeeper and schedule a game for a specific date and time.
- **Notifications:** Goalkeepers are notified when they are selected for a game.
- **Ratings and Reviews:** After each game, players can rate the goalkeeper's performance (from 1 to 5 stars) and leave a comment.
- **Map of Fields:** A feature to view football fields. Fields can be added by users (pending approval) or by administrators.
- **Guest Mode:** Users can explore the app's features without creating an account.
- **Announcements:** Users can create and view game announcements.

## User Stories

The development of this application was guided by the following user stories:

- **As a player, I want to be able to...**
    - Register, log in, and manage my profile.
    - Search for available goalkeepers and filter them by city.
    - View a goalkeeper's profile and availability.
    - Book a goalkeeper for a specific date and time.
    - Rate a goalkeeper's performance and leave a review after a game.
    - View a map of available football fields.
    - Suggest new football fields to be added to the platform.
- **As a goalkeeper, I want to be able to...**
    - Register, log in, and manage my profile, including my price per game.
    - Set and manage my availability.
    - Receive notifications for new booking requests.
    - Confirm or decline booking requests.
    - View my upcoming and past games.

## Technology Stack

- **Frontend:** Flutter (Dart)
- **Backend & Database:** Supabase (PostgreSQL, Auth, Edge Functions)
- **Maps:** `flutter_map` with OpenStreetMap
- **State Management:** Provider
- **Notifications:** Firebase Cloud Messaging (FCM)
- **HTTP Client:** `http`
- **Environment Variables:** `flutter_dotenv`
- **Dependencies:**
    - `cupertino_icons`
    - `font_awesome_flutter`
    - `google_fonts`
    - `supabase_flutter`
    - `provider`
    - `flutter_dotenv`
    - `firebase_core`
    - `firebase_messaging`
    - `permission_handler`
    - `flutter_map`
    - `latlong2`
    - `geolocator`
    - `intl`
    - `cached_network_image`
    - `flutter_svg`
- **Dev Dependencies:**
    - `flutter_test`
    - `flutter_lints`
    - `mockito`
    - `build_runner`

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

- Flutter SDK
- A Supabase project
- A Firebase project

### Installation

1.  **Clone the repo**
    ```sh
    git clone https://github.com/your_username/Goalkeeper-Finder.git
    ```
2.  **Install packages**
    ```sh
    flutter pub get
    ```
3.  **Set up environment variables**
    Create a `.env` file in the root of the project and add the following:
    ```
    SUPABASE_URL=YOUR_SUPABASE_URL
    SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
    ```
4.  **Run the app**
    ```sh
    flutter run
    ```

## Database Schema

The database consists of the following tables:

- `users`: Stores user profile information.
- `availabilities`: Stores the availability of goalkeepers.
- `bookings`: Stores information about booked games.
- `ratings`: Stores player ratings for goalkeepers.
- `fields`: Stores information about football fields.
- `player_stats`: Stores player performance statistics.
- `teams`: Stores team information.
- `team_stats`: Stores team performance statistics.
- `announcements`: Stores game announcements.
- `announcement_participants`: Stores participants for each announcement.

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.
