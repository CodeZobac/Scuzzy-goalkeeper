// Example usage of the Guest Mode Infrastructure
// This file demonstrates how to use the guest mode components

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_state_provider.dart';
import '../data/models/registration_prompt_config.dart';
import '../../core/utils/guest_mode_utils.dart';

/// Example widget showing how to use AuthStateProvider
class GuestModeExample extends StatelessWidget {
  const GuestModeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateProvider>(
      builder: (context, authProvider, child) {
        // Initialize guest context if user is in guest mode
        if (authProvider.isGuest && authProvider.guestContext == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            authProvider.initializeGuestContext();
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(authProvider.isGuest ? 'Guest Mode' : 'Authenticated'),
          ),
          body: Column(
            children: [
              // Display current auth state
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auth State: ${authProvider.isGuest ? 'Guest' : 'Authenticated'}'),
                      if (authProvider.isGuest && authProvider.guestContext != null) ...[
                        Text('Session ID: ${authProvider.guestContext!.sessionId}'),
                        Text('Content Viewed: ${authProvider.guestContext!.viewedContent.length}'),
                        Text('Prompts Shown: ${authProvider.guestContext!.promptsShown}'),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Example buttons for guest actions
              if (authProvider.isGuest) ...[
                ElevatedButton(
                  onPressed: () => _handleViewContent(context, authProvider, 'announcement_1'),
                  child: const Text('View Announcement'),
                ),
                ElevatedButton(
                  onPressed: () => _handleRestrictedAction(context, authProvider, 'join_match'),
                  child: const Text('Join Match (Requires Auth)'),
                ),
                ElevatedButton(
                  onPressed: () => _handleRestrictedAction(context, authProvider, 'hire_goalkeeper'),
                  child: const Text('Hire Goalkeeper (Requires Auth)'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _handleViewContent(BuildContext context, AuthStateProvider authProvider, String content) {
    // Track content viewing for guest users
    authProvider.trackGuestContentView(content);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewed: $content')),
    );
  }

  void _handleRestrictedAction(BuildContext context, AuthStateProvider authProvider, String action) {
    // Check if action requires authentication
    if (GuestModeUtils.actionRequiresAuth(action)) {
      // Show registration prompt if appropriate
      if (authProvider.shouldShowRegistrationPrompt()) {
        _showRegistrationPrompt(context, authProvider, action);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please create an account to continue')),
        );
      }
    }
  }

  void _showRegistrationPrompt(BuildContext context, AuthStateProvider authProvider, String action) {
    final config = RegistrationPromptConfig.forContext(action);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(config.title),
        content: Text(config.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(config.secondaryButtonText),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.promptForRegistration(action);
              
              // Navigate to signup (in real app)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigating to signup...')),
              );
            },
            child: Text(config.primaryButtonText),
          ),
        ],
      ),
    );
  }
}

/// Example of how to check route access
class RouteGuardExample {
  static bool canAccessRoute(String route) {
    if (GuestModeUtils.isGuest) {
      return GuestModeUtils.isGuestAccessibleRoute(route);
    }
    return true; // Authenticated users can access all routes
  }
  
  static String getRedirectRoute(String attemptedAction) {
    if (GuestModeUtils.isGuest) {
      return GuestModeUtils.getGuestRedirectRoute(attemptedAction);
    }
    return '/home'; // Default for authenticated users
  }
}

/// Example of feature access checking
class FeatureAccessExample {
  static bool canAccessFeature(String feature) {
    if (GuestModeUtils.isGuest) {
      return GuestModeUtils.canGuestAccess(feature);
    }
    return true; // Authenticated users can access all features
  }
  
  static void handleFeatureAccess(BuildContext context, String feature) {
    if (!canAccessFeature(feature)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an account to access this feature'),
        ),
      );
    }
  }
}