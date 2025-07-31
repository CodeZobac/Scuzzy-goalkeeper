# Complete Forgot Password Feature with Guest Mode Support

## Overview

This implementation provides a complete "forgot password" feature for your Flutter application that properly handles the guest mode challenge. The solution includes proper state management, deep linking, and seamless transitions between guest and authenticated states.

## Implementation Components

### 1. Enhanced AuthRepository (`lib/src/features/auth/data/auth_repository.dart`)

```dart
Future<void> resetPasswordForEmail(String email) async {
  // Configure the redirect URL for password reset
  // For web development, use localhost. For mobile, use custom scheme
  const String redirectUrl = 'http://localhost:3000/#/reset-password';
  
  await _supabase.auth.resetPasswordForEmail(
    email,
    redirectTo: redirectUrl,
  );
}

Future<void> updatePassword(String newPassword) async {
  await _supabase.auth.updateUser(
    UserAttributes(password: newPassword),
  );
}
```

### 2. Enhanced Reset Password Screen (`lib/src/features/auth/presentation/screens/reset_password_screen.dart`)

The reset password screen includes:
- **Guest Mode Handling**: Automatically clears guest state when entering password recovery
- **Session Validation**: Checks for valid password recovery sessions
- **Password Requirements**: Shows real-time validation of password strength
- **Error Handling**: Comprehensive error management with user-friendly messages
- **State Management**: Proper integration with AuthStateProvider

Key features:
- Listens for `AuthChangeEvent.passwordRecovery` events
- Clears guest context when in recovery mode
- Validates password recovery sessions
- Shows password strength requirements in real-time

### 3. Deep Link Service (`lib/src/core/services/deep_link_service.dart`)

Handles both mobile deep links and web URL fragments:
- Mobile: `io.supabase.goalkeeper://reset-password`
- Web: `http://localhost:3000/#/reset-password`

### 4. Enhanced AuthStateProvider

New method for password recovery mode:
```dart
void handlePasswordRecoveryMode() {
  // Clear guest state when in password recovery
  if (_guestContext != null) {
    clearGuestContext();
  }
  
  // Clear any intended destination since password reset takes priority
  _intendedDestination = null;
  _destinationArguments = null;
  
  notifyListeners();
}
```

## Platform Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- Deep link intent filter for password reset -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.supabase.goalkeeper" />
</intent-filter>
```

### iOS (`ios/Runner/Info.plist`)

```xml
<!-- Deep link URL scheme for password reset -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>io.supabase.goalkeeper</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.goalkeeper</string>
        </array>
    </dict>
</array>
```

## Guest Mode Challenge Solution

The implementation addresses the guest mode challenge through:

### 1. State Detection
- Automatically detects when the app is in guest mode
- Identifies password recovery sessions via deep links or URL fragments

### 2. State Transition Management
```dart
void _checkPasswordRecoverySession() {
  final authProvider = context.read<AuthStateProvider>();
  
  // Clear any existing guest context since we're in a password recovery flow
  if (authProvider.isGuest) {
    authProvider.clearGuestContext();
  }

  // Listen for password recovery events
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      setState(() {
        _isValidSession = true;
      });
    }
  });
}
```

### 3. Session Validation
- Ensures the temporary authenticated session from password recovery is valid
- Blocks password updates if session is invalid
- Provides clear error messages for expired links

## Testing Instructions

### Web Testing (Chrome)

1. **Start the app on the correct port:**
   ```bash
   flutter run -d chrome --web-port=3000
   ```

2. **Test the complete flow:**
   - Navigate to the test screen (`/deep-link-test`)
   - Initialize guest mode
   - Use "Test Forgot Password Flow"
   - Enter a valid email address
   - Check your email for the reset link
   - Click the reset link (will open `http://localhost:3000/#/reset-password`)
   - The app should automatically navigate to the reset password screen
   - Enter a new password and confirm

3. **Alternative local testing:**
   - Use "Simulate Password Reset (Web)" button
   - This bypasses email and directly tests the reset flow

### Mobile Testing

1. **Build and install the app:**
   ```bash
   flutter build apk --debug
   flutter install
   ```

2. **Test with real email:**
   - Complete the forgot password flow
   - Check email on the mobile device
   - Tap the reset link
   - The app should open and navigate to reset password screen

3. **Test with deep link simulation:**
   - Use `adb` to simulate deep links:
   ```bash
   adb shell am start 
     -W -a android.intent.action.VIEW 
     -d "io.supabase.goalkeeper://reset-password" 
     com.example.goalkeeper
   ```

## Key Features

### Guest Mode Handling
- ✅ Automatically detects guest state
- ✅ Clears guest context during password recovery
- ✅ Preserves intended destinations when appropriate
- ✅ Handles state transitions seamlessly

### Password Reset Flow
- ✅ Validates email addresses
- ✅ Sends reset emails with proper redirect URLs
- ✅ Handles both mobile and web deep links
- ✅ Validates password recovery sessions
- ✅ Shows real-time password requirements
- ✅ Comprehensive error handling

### Security Considerations
- ✅ Non-committal success messages (prevents email enumeration)
- ✅ Session validation for password updates
- ✅ Secure password requirements
- ✅ Proper error handling without revealing sensitive information

## Troubleshooting

### Common Issues

1. **Redirect to home instead of reset screen:**
   - Ensure the correct port is used: `--web-port=3000`
   - Check that the redirect URL matches the running port
   - Verify the URL fragment parsing in `_getInitialRoute()`

2. **Deep links not working on mobile:**
   - Verify AndroidManifest.xml configuration
   - Check iOS Info.plist setup
   - Ensure the app is properly installed

3. **Password recovery session invalid:**
   - Check that the reset link is recent (they expire)
   - Verify Supabase auth configuration
   - Ensure the redirect URL is correctly configured in Supabase

4. **Guest state not clearing:**
   - Check AuthStateProvider integration
   - Verify the `handlePasswordRecoveryMode()` is called
   - Ensure proper context management

## Testing Checklist

- [ ] App runs on port 3000 (`flutter run -d chrome --web-port=3000`)
- [ ] Guest mode initializes correctly
- [ ] Forgot password form validates email
- [ ] Reset email is sent with correct redirect URL
- [ ] Reset link opens app and navigates to reset screen
- [ ] Guest state is cleared during password recovery
- [ ] Password requirements are shown and validated
- [ ] Password update succeeds with valid session
- [ ] Error handling works for invalid sessions
- [ ] User is redirected to login after successful reset
- [ ] Mobile deep links work (if testing on mobile)

## Next Steps

1. **Production Configuration:**
   - Update redirect URLs for production domains
   - Configure Supabase auth settings for production
   - Test on real mobile devices

2. **Enhanced Features:**
   - Add password strength meter
   - Implement rate limiting for reset requests
   - Add email template customization
   - Include analytics for guest mode transitions

3. **Security Enhancements:**
   - Add CAPTCHA for reset requests
   - Implement additional session validation
   - Add audit logging for password changes

## Implementation Details

### 1. Deep Link Configuration

#### Android (AndroidManifest.xml)
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.supabase.goalkeeper" />
</intent-filter>
```

#### iOS (Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>io.supabase.goalkeeper</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.goalkeeper</string>
        </array>
    </dict>
</array>
```

### 2. Auth Repository Enhancement

The `AuthRepository` now uses proper redirect URLs:

```dart
Future<void> resetPasswordForEmail(String email) async {
  await _supabase.auth.resetPasswordForEmail(
    email,
    redirectTo: 'io.supabase.goalkeeper://reset-password',
  );
}

Future<void> updatePassword(String newPassword) async {
  await _supabase.auth.updateUser(
    UserAttributes(password: newPassword),
  );
}
```

### 3. Deep Link Service

The `DeepLinkService` handles:
- App launch from deep links
- Runtime deep link processing
- Password reset link detection
- Error handling and logging

Key features:
- Singleton pattern for consistent access
- Callback system for route handling
- Automatic initialization on app startup
- Comprehensive error logging

### 4. Guest Mode State Management

The `AuthStateProvider` includes new methods:

```dart
void handlePasswordRecoveryMode() {
  // Clear guest state when entering password recovery
  if (_guestContext != null) {
    clearGuestContext();
  }
  
  // Clear intended destinations
  _intendedDestination = null;
  _destinationArguments = null;
  
  notifyListeners();
}
```

### 5. Reset Password Screen Features

The comprehensive reset password screen includes:

- **Session Validation**: Checks for valid password recovery session
- **Guest Mode Clearing**: Automatically clears guest state
- **Password Requirements**: Real-time validation display
- **Error Handling**: Comprehensive error management
- **Animation**: Smooth UI transitions
- **Multiple States**: Form, success, and invalid session views

### 6. Main App Integration

The main app handles:
- Deep link initialization on startup
- Auth state change listening including `AuthChangeEvent.passwordRecovery`
- Route generation for password reset flows
- Guest mode initialization and cleanup

## Usage Flow

### Normal Password Reset Flow

1. User clicks "Forgot Password" in sign-in screen
2. User enters email in `ForgotPasswordScreen`
3. Supabase sends email with deep link
4. User clicks link in email
5. App opens to `ResetPasswordScreen`
6. User enters new password
7. User is redirected to sign-in screen

### Guest Mode Challenge Flow

1. User is browsing app in guest mode
2. User receives password reset email (from previous request)
3. User clicks password reset link
4. **Deep link handler detects password reset URL**
5. **Guest context is automatically cleared**
6. **App navigates to reset password screen**
7. **Temporary auth session is utilized for password update**
8. User completes password reset
9. User is redirected to sign-in screen

## Key Technical Solutions

### 1. Auth State Listening

```dart
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  if (data.event == AuthChangeEvent.passwordRecovery) {
    final authProvider = context.read<AuthStateProvider>();
    authProvider.handlePasswordRecoveryMode();
  }
});
```

### 2. Deep Link Route Handling

```dart
DeepLinkService.instance.setDeepLinkCallback((Uri uri) {
  if (uri.scheme == 'io.supabase.goalkeeper' && uri.host == 'reset-password') {
    final authProvider = context.read<AuthStateProvider>();
    authProvider.handlePasswordRecoveryMode();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/reset-password',
      (route) => false,
    );
  }
});
```

### 3. Session Validation

```dart
void _checkPasswordRecoverySession() {
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      setState(() {
        _isValidSession = true;
      });
    }
  });
}
```

## Testing

### Manual Testing Steps

1. **Test Guest Mode Initialization**
   - Launch app
   - Verify guest context is created
   - Navigate to test screen (`/test-deep-link`)

2. **Test Forgot Password Flow**
   - Navigate to sign-in screen
   - Click "Forgot Password"
   - Enter valid email
   - Check email for reset link

3. **Test Deep Link Handling**
   - While in guest mode, open reset link
   - Verify guest context is cleared
   - Verify navigation to reset password screen

4. **Test Password Reset**
   - Enter new password meeting requirements
   - Verify password update succeeds
   - Verify navigation to sign-in screen

### Automated Testing

The implementation includes a test screen (`TestDeepLinkScreen`) that provides:
- Current state visualization
- Manual action buttons
- Event logging
- Deep link simulation

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  uni_links: ^0.5.1  # For deep link handling
```

## Error Handling

The implementation includes comprehensive error handling:

- Network connectivity issues
- Invalid email addresses
- Weak passwords
- Expired or invalid reset links
- Auth session errors
- Deep link parsing errors

All errors are logged using the app's error logging system and displayed to users with appropriate messages.

## Security Considerations

1. **Email Enumeration Prevention**: Success messages are non-committal
2. **Session Validation**: Reset links are validated before allowing password updates
3. **Password Requirements**: Strong password validation is enforced
4. **State Isolation**: Guest mode is properly cleared during password recovery

## Troubleshooting

### Common Issues

1. **Deep links not working**
   - Verify Android manifest and iOS plist configuration
   - Check URL scheme matches exactly
   - Test on physical device, not emulator

2. **Password reset not working**
   - Verify Supabase project settings
   - Check email template configuration
   - Ensure redirect URL is whitelisted in Supabase

3. **Guest mode not clearing**
   - Check auth state provider integration
   - Verify deep link callback is set up
   - Review auth state change listeners

### Debug Tools

1. Use the test screen (`/test-deep-link`) to monitor state changes
2. Check app logs for deep link events
3. Monitor Supabase auth events in dashboard
4. Use browser developer tools to test deep link URLs

## Conclusion

This implementation provides a robust, user-friendly password reset flow that seamlessly handles the transition from guest mode to authenticated password recovery. The modular design ensures maintainability while the comprehensive error handling provides a smooth user experience.
