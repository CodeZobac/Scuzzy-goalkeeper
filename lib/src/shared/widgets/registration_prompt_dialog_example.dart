import 'package:flutter/material.dart';
import 'package:goalkeeper/src/shared/widgets/registration_prompt_dialog.dart';
import 'package:goalkeeper/src/features/auth/presentation/theme/app_theme.dart';

/// Example screen demonstrating how to use the RegistrationPromptDialog
class RegistrationPromptExampleScreen extends StatelessWidget {
  const RegistrationPromptExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Prompt Examples'),
        backgroundColor: AppTheme.primaryBackground,
      ),
      backgroundColor: AppTheme.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registration Prompt Dialog Examples',
                style: AppTheme.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Join Match Example
              _buildExampleButton(
                context,
                'Join Match Prompt',
                'Show dialog for joining a match',
                Icons.sports_soccer,
                () => RegistrationPromptHelper.showJoinMatchPrompt(context),
              ),
              
              const SizedBox(height: 16),
              
              // Hire Goalkeeper Example
              _buildExampleButton(
                context,
                'Hire Goalkeeper Prompt',
                'Show dialog for hiring a goalkeeper',
                Icons.sports_handball,
                () => RegistrationPromptHelper.showHireGoalkeeperPrompt(context),
              ),
              
              const SizedBox(height: 16),
              
              // Profile Access Example
              _buildExampleButton(
                context,
                'Profile Access Prompt',
                'Show dialog for profile access',
                Icons.account_circle,
                () => RegistrationPromptHelper.showProfileAccessPrompt(context),
              ),
              
              const SizedBox(height: 16),
              
              // Custom Example
              _buildExampleButton(
                context,
                'Custom Prompt',
                'Show custom registration prompt',
                Icons.star,
                () => _showCustomPrompt(context),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Tap any button to see the registration prompt dialog in action.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.secondaryText,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomPrompt(BuildContext context) {
    const customConfig = RegistrationPromptConfig(
      title: 'Unlock Premium Features!',
      message: 'Get access to exclusive features and premium content by creating your account today.',
      context: 'premium_features',
      icon: Icons.diamond,
      primaryButtonText: 'Get Premium',
      secondaryButtonText: 'Not Now',
    );

    RegistrationPromptHelper.showCustomPrompt(context, customConfig);
  }
}

/// Example of how to integrate registration prompts in your app flow
class IntegrationExample {
  /// Example: Show registration prompt when user tries to join a match
  static void handleJoinMatchAction(BuildContext context) {
    // Check if user is authenticated
    final isAuthenticated = false; // Replace with actual auth check
    
    if (!isAuthenticated) {
      // Show registration prompt
      RegistrationPromptHelper.showJoinMatchPrompt(context);
    } else {
      // Proceed with join match logic
      _proceedWithJoinMatch(context);
    }
  }

  /// Example: Show registration prompt when user tries to hire a goalkeeper
  static void handleHireGoalkeeperAction(BuildContext context) {
    // Check if user is authenticated
    final isAuthenticated = false; // Replace with actual auth check
    
    if (!isAuthenticated) {
      // Show registration prompt with custom callbacks
      showDialog(
        context: context,
        builder: (context) => RegistrationPromptDialog(
          config: RegistrationPromptConfig.hireGoalkeeper(),
          onRegisterPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/signup');
          },
          onCancelPressed: () {
            Navigator.of(context).pop();
            // Maybe show a snackbar or alternative action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You can browse goalkeepers without an account, but registration is required to hire.'),
              ),
            );
          },
        ),
      );
    } else {
      // Proceed with hire goalkeeper logic
      _proceedWithHireGoalkeeper(context);
    }
  }

  static void _proceedWithJoinMatch(BuildContext context) {
    // Implementation for joining match
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Joining match...')),
    );
  }

  static void _proceedWithHireGoalkeeper(BuildContext context) {
    // Implementation for hiring goalkeeper
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proceeding to hire goalkeeper...')),
    );
  }
}