import '../models/guest_user_context.dart';
import '../models/registration_prompt_config.dart';

/// Manages smart prompt frequency to avoid over-prompting guest users
class SmartPromptManager {
  static final SmartPromptManager _instance = SmartPromptManager._internal();
  factory SmartPromptManager() => _instance;
  SmartPromptManager._internal();

  static SmartPromptManager get instance => _instance;

  // Track prompt history across sessions (in a real app, this might be persisted)
  final Map<String, List<DateTime>> _promptHistory = {};
  final Map<String, int> _promptDismissals = {};

  /// Check if we should show a prompt based on smart frequency management
  bool shouldShowPrompt(String promptContext, GuestUserContext guestContext) {
    // Check basic engagement first (content or actions)
    if (guestContext.viewedContent.isEmpty && guestContext.actionAttempts.isEmpty) {
      return false;
    }

    // Check session-based limits
    if (guestContext.promptsShown >= _getMaxPromptsForSession(guestContext)) {
      return false;
    }

    // Check context-specific frequency limits
    if (_isPromptContextOverused(promptContext)) {
      return false;
    }

    // Check if user has been dismissing prompts frequently
    if (_isUserPromptFatigued(promptContext)) {
      return false;
    }

    // Check engagement-based timing
    if (!_isGoodTimingForPrompt(guestContext)) {
      return false;
    }

    return true;
  }

  /// Record that a prompt was shown
  void recordPromptShown(String promptContext) {
    final now = DateTime.now();
    _promptHistory.putIfAbsent(promptContext, () => []).add(now);
    
    // Keep only recent history (last 24 hours)
    _promptHistory[promptContext]!.removeWhere(
      (time) => now.difference(time).inHours > 24
    );
  }

  /// Record that a prompt was dismissed
  void recordPromptDismissed(String promptContext) {
    _promptDismissals[promptContext] = (_promptDismissals[promptContext] ?? 0) + 1;
  }

  /// Get the optimal prompt configuration based on context and user behavior
  RegistrationPromptConfig getOptimalPromptConfig(String baseContext, GuestUserContext guestContext) {
    final baseConfig = RegistrationPromptConfig.forContext(baseContext);
    
    // Customize message based on engagement level
    if (guestContext.isHighlyEngaged) {
      return _getEngagedUserPrompt(baseConfig, guestContext);
    } else {
      return _getCasualUserPrompt(baseConfig, guestContext);
    }
  }

  /// Get maximum prompts allowed for current session based on engagement
  int _getMaxPromptsForSession(GuestUserContext guestContext) {
    if (guestContext.isHighlyEngaged) {
      return 4; // Allow more prompts for engaged users
    } else if (guestContext.engagementScore >= 1.5) {
      return 3; // Standard limit for moderately engaged users
    } else {
      return 2; // Fewer prompts for less engaged users
    }
  }

  /// Check if a prompt context has been overused recently
  bool _isPromptContextOverused(String promptContext) {
    final history = _promptHistory[promptContext] ?? [];
    final now = DateTime.now();
    
    // Don't show same prompt type more than twice in 1 hour
    final recentPrompts = history.where(
      (time) => now.difference(time).inHours < 1
    ).length;
    
    return recentPrompts >= 2;
  }

  /// Check if user shows signs of prompt fatigue
  bool _isUserPromptFatigued(String promptContext) {
    final dismissals = _promptDismissals[promptContext] ?? 0;
    
    // If user has dismissed this type of prompt 3+ times, they're fatigued
    return dismissals >= 3;
  }

  /// Check if it's good timing for a prompt based on user activity
  bool _isGoodTimingForPrompt(GuestUserContext guestContext) {
    // Don't prompt immediately after user starts session (first 30 seconds)
    if (guestContext.sessionDuration.inSeconds < 30) {
      return false;
    }

    // Don't prompt if user has been inactive for too long
    if (guestContext.timeSinceLastActivity.inMinutes > 5) {
      return false;
    }

    // Good timing if user has been active and engaged
    return guestContext.viewedContent.isNotEmpty || guestContext.actionAttempts.isNotEmpty;
  }

  /// Get prompt configuration for highly engaged users
  RegistrationPromptConfig _getEngagedUserPrompt(RegistrationPromptConfig baseConfig, GuestUserContext guestContext) {
    final actionCount = guestContext.actionAttempts.values.fold(0, (sum, attempts) => sum + attempts);
    
    String enhancedMessage = baseConfig.message;
    
    if (actionCount > 0) {
      enhancedMessage = 'Vemos que você está interessado em participar! ${baseConfig.message}';
    } else if (guestContext.viewedContent.length > 3) {
      enhancedMessage = 'Você já explorou bastante conteúdo! ${baseConfig.message}';
    }

    return RegistrationPromptConfig(
      title: baseConfig.title,
      message: enhancedMessage,
      primaryButtonText: 'Vamos Começar!',
      secondaryButtonText: 'Talvez Depois',
      context: baseConfig.context,
      metadata: {
        ...baseConfig.metadata,
        'user_engagement': 'high',
        'engagement_score': guestContext.engagementScore,
      },
    );
  }

  /// Get prompt configuration for casual users
  RegistrationPromptConfig _getCasualUserPrompt(RegistrationPromptConfig baseConfig, GuestUserContext guestContext) {
    return RegistrationPromptConfig(
      title: baseConfig.title,
      message: '${baseConfig.message}\n\nÉ rápido e gratuito!',
      primaryButtonText: baseConfig.primaryButtonText,
      secondaryButtonText: 'Continuar Explorando',
      context: baseConfig.context,
      metadata: {
        ...baseConfig.metadata,
        'user_engagement': 'casual',
        'engagement_score': guestContext.engagementScore,
      },
    );
  }

  /// Reset prompt history (for testing or privacy)
  void resetPromptHistory() {
    _promptHistory.clear();
    _promptDismissals.clear();
  }

  /// Get prompt statistics for analytics
  Map<String, dynamic> getPromptStatistics() {
    final stats = <String, dynamic>{};
    
    for (final entry in _promptHistory.entries) {
      final context = entry.key;
      final history = entry.value;
      final dismissals = _promptDismissals[context] ?? 0;
      
      stats[context] = {
        'total_shown': history.length,
        'total_dismissed': dismissals,
        'recent_shown_1h': history.where(
          (time) => DateTime.now().difference(time).inHours < 1
        ).length,
        'recent_shown_24h': history.length,
        'dismissal_rate': history.isNotEmpty ? dismissals / history.length : 0.0,
      };
    }
    
    return stats;
  }
}