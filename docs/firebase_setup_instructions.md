# Firebase Setup Instructions

Your app is currently failing to initialize Firebase because the configuration files are missing. Here's how to set up Firebase properly:

## 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or use an existing project
3. Follow the setup wizard

## 2. Add Android App

1. In your Firebase project, click "Add app" and select Android
2. Use your Android package name from `android/app/build.gradle` (usually something like `com.example.goalkeeper`)
3. Download the `google-services.json` file
4. Place it in `android/app/google-services.json`

## 3. Add iOS App

1. In your Firebase project, click "Add app" and select iOS
2. Use your iOS bundle ID from `ios/Runner/Info.plist`
3. Download the `GoogleService-Info.plist` file
4. Place it in `ios/Runner/GoogleService-Info.plist`

## 4. Enable Firebase Cloud Messaging

1. In Firebase Console, go to "Cloud Messaging"
2. Enable the service
3. Note down your Server Key (you'll need this for backend push notifications)

## 5. Configure Android

Make sure your `android/app/build.gradle` has:

```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.0.0'
    // other dependencies
}
```

And your `android/build.gradle` has:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
    // other dependencies
}
```

## 6. Configure iOS

Add to your `ios/Runner/Info.plist`:

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

## 7. Test the Setup

After adding the configuration files, run:

```bash
flutter clean
flutter pub get
flutter run
```

## Current Status

- ✅ Firebase packages are installed in pubspec.yaml
- ❌ `google-services.json` missing (Android)
- ❌ `GoogleService-Info.plist` missing (iOS)
- ✅ Code is configured to handle missing Firebase gracefully

## Temporary Workaround

The app will continue to work without Firebase, but push notifications will be disabled. The notification system will still work for in-app notifications and database notifications.
