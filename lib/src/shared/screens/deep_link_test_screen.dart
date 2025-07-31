import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../core/services/deep_link_service.dart';
import '../../features/auth/presentation/theme/app_theme.dart';

class DeepLinkTestScreen extends StatefulWidget {
  const DeepLinkTestScreen({super.key});

  @override
  State<DeepLinkTestScreen> createState() => _DeepLinkTestScreenState();
}

class _DeepLinkTestScreenState extends State<DeepLinkTestScreen> {
  String _deepLinkStatus = 'No deep link received';
  Uri? _lastReceivedUri;

  @override
  void initState() {
    super.initState();
    
    // Set up deep link callback to monitor incoming links
    DeepLinkService.instance.setDeepLinkCallback((Uri uri) {
      setState(() {
        _deepLinkStatus = 'Deep link received: $uri';
        _lastReceivedUri = uri;
      });
    });
  }

  void _simulatePasswordResetDeepLink() {
    // For web testing, simulate the URL fragment approach
    final authProvider = context.read<AuthStateProvider>();
    authProvider.handlePasswordRecoveryMode();
    
    setState(() {
      _deepLinkStatus = 'Simulating web password reset URL: http://localhost:3000/#/reset-password';
    });
    
    // Navigate to reset password screen
    Navigator.of(context).pushNamed('/reset-password');
  }

  void _testForgotPasswordFlow() {
    // Navigate to forgot password screen to test the complete flow
    Navigator.of(context).pushNamed('/forgot-password');
  }

  void _clearGuestMode() {
    final authProvider = context.read<AuthStateProvider>();
    authProvider.clearGuestContext();
    setState(() {});
  }

  void _initializeGuestMode() {
    final authProvider = context.read<AuthStateProvider>();
    authProvider.initializeGuestContext();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Link & Guest Mode Test'),
        backgroundColor: AppTheme.authPrimaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Guest Mode Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest Mode Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Is Guest: ${authProvider.isGuest}'),
                    Text('Has Guest Context: ${authProvider.guestContext != null}'),
                    if (authProvider.guestContext != null)
                      Text('Session ID: ${authProvider.guestContext!.sessionId}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Deep Link Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deep Link Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_deepLinkStatus),
                    if (_lastReceivedUri != null) ...[
                      const SizedBox(height: 8),
                      Text('Scheme: ${_lastReceivedUri!.scheme}'),
                      Text('Host: ${_lastReceivedUri!.host}'),
                      Text('Path: ${_lastReceivedUri!.path}'),
                      Text('Query: ${_lastReceivedUri!.query}'),
                    ],
                    if (DeepLinkService.instance.initialUri != null) ...[
                      const SizedBox(height: 8),
                      Text('Initial URI: ${DeepLinkService.instance.initialUri}'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Actions
            Text(
              'Test Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _testForgotPasswordFlow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.authPrimaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Forgot Password Flow'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _simulatePasswordResetDeepLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simulate Password Reset (Web)'),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _initializeGuestMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Initialize Guest Mode'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearGuestMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear Guest Mode'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Test Password Reset with Guest Mode:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Initialize Guest Mode (if not already active)\n'
                      '2. Tap "Test Forgot Password Flow"\n'
                      '3. Enter email and request reset link\n'
                      '4. Check email and click the reset link\n'
                      '5. The app should handle the transition from guest to reset mode\n'
                      '\nFor Web Testing:\n'
                      '- The reset link will redirect to http://localhost:3000/#/reset-password\n'
                      '- Make sure to run: flutter run -d chrome --web-port=3000\n'
                      '- Or tap "Simulate Password Reset (Web)" to test locally',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
