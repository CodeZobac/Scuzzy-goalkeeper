import 'package:flutter/material.dart';
import '../widgets/registration_prompt_dialog.dart';
import '../../features/auth/data/models/registration_prompt_config.dart';

/// Helper class for showing registration prompts throughout the app
/// 
/// This class provides convenient static methods for showing registration
/// prompts in different contexts. It handles the dialog display and
/// navigation to the signup screen if the user chooses to register.
class RegistrationPromptHelper {
  /// Show a join match registration prompt
  static Future<void> showJoinMatchPrompt(BuildContext context) async {
    final result = await RegistrationPromptDialogUtils.showJoinMatchPrompt(context);
    if (result == true && context.mounted) {
      Navigator.of(context).pushNamed('/signup');
    }
  }

  /// Show a hire goalkeeper registration prompt
  static Future<void> showHireGoalkeeperPrompt(BuildContext context) async {
    final result = await RegistrationPromptDialogUtils.showHireGoalkeeperPrompt(context);
    if (result == true && context.mounted) {
      Navigator.of(context).pushNamed('/signup');
    }
  }

  /// Show a profile access registration prompt
  static Future<void> showProfileAccessPrompt(BuildContext context) async {
    final result = await RegistrationPromptDialogUtils.showProfileAccessPrompt(context);
    if (result == true && context.mounted) {
      Navigator.of(context).pushNamed('/signup');
    }
  }

  /// Show a create announcement registration prompt
  static Future<void> showCreateAnnouncementPrompt(BuildContext context) async {
    final result = await RegistrationPromptDialogUtils.showCreateAnnouncementPrompt(context);
    if (result == true && context.mounted) {
      Navigator.of(context).pushNamed('/signup');
    }
  }

  /// Show a custom registration prompt
  static Future<void> showCustomPrompt(
    BuildContext context,
    RegistrationPromptConfig config,
  ) async {
    final result = await RegistrationPromptDialogUtils.show(context, config);
    if (result == true && context.mounted) {
      Navigator.of(context).pushNamed('/signup');
    }
  }

  /// Show a generic registration prompt with default configuration
  static Future<void> showGenericPrompt(BuildContext context) async {
    final result = await RegistrationPromptDialogUtils.show(
      context,
      RegistrationPromptConfig.forContext('default'),
    );
    if (result == true && context.mounted) {
      Navigator.of(context).pushNamed('/signup');
    }
  }
}