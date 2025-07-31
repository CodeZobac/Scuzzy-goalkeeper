import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/presentation/providers/auth_state_provider.dart';
import '../core/services/deep_link_service.dart';
import '../features/auth/presentation/theme/app_theme.dart';

class TestDeepLinkScreen extends StatefulWidget {
  const TestDeepLinkScreen({super.key});

  @override
  State<TestDeepLinkScreen> createState() => _TestDeepLinkScreenState();
}

class _TestDeepLinkScreenState extends State<TestDeepLinkScreen> {
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _setupDeepLinkListener();
  }

  void _setupDeepLinkListener() {
    DeepLinkService.instance.setDeepLinkCallback((Uri uri) {
      setState(() {
        _logs.add('Deep link received: $uri');
      });
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthStateProvider>();
    final currentSession = Supabase.instance.client.auth.currentSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Link Test'),
        backgroundColor: AppTheme.authPrimaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Guest Mode: ${authProvider.isGuest}'),
                    Text('Has Session: ${currentSession != null}'),
                    Text('Session User: ${currentSession?.user?.email ?? 'None'}'),
                    Text('Guest Context: ${authProvider.guestContext != null}'),
                    if (DeepLinkService.instance.initialUri != null)
                      Text('Initial URI: ${DeepLinkService.instance.initialUri}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Action Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Actions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/forgot-password');
                            _addLog('Navigated to forgot password');
                          },
                          child: const Text('Forgot Password'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/reset-password');
                            _addLog('Navigated to reset password');
                          },
                          child: const Text('Reset Password'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            authProvider.clearGuestContext();
                            _addLog('Cleared guest context');
                          },
                          child: const Text('Clear Guest'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            authProvider.initializeGuestContext();
                            _addLog('Initialized guest context');
                          },
                          child: const Text('Init Guest'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            authProvider.handlePasswordRecoveryMode();
                            _addLog('Triggered password recovery mode');
                          },
                          child: const Text('Recovery Mode'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _logs.clear();
                            });
                          },
                          child: const Text('Clear Logs'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logs Section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Logs',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  _logs[index],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Test in guest mode: Use "Init Guest" button\n'
                      '2. Test forgot password flow: Tap "Forgot Password"\n'
                      '3. Simulate deep link: Open link "io.supabase.goalkeeper://reset-password"\n'
                      '4. Check logs for deep link events\n'
                      '5. Verify guest context is cleared during password recovery',
                      style: TextStyle(fontSize: 12),
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
