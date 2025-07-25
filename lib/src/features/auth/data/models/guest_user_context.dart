/// Model for tracking guest user context and engagement
class GuestUserContext {
  final String sessionId;
  final DateTime sessionStart;
  final List<String> viewedContent;
  final int promptsShown;
  final Map<String, dynamic> metadata;
  final Map<String, int> actionAttempts;
  final DateTime lastActivity;
  
  const GuestUserContext({
    required this.sessionId,
    required this.sessionStart,
    this.viewedContent = const [],
    this.promptsShown = 0,
    this.metadata = const {},
    this.actionAttempts = const {},
    DateTime? lastActivity,
  }) : lastActivity = lastActivity ?? sessionStart;
  
  /// Create a new guest user context
  factory GuestUserContext.create() {
    final now = DateTime.now();
    return GuestUserContext(
      sessionId: 'guest_${now.millisecondsSinceEpoch}',
      sessionStart: now,
      lastActivity: now,
    );
  }
  
  /// Copy with updated values
  GuestUserContext copyWith({
    String? sessionId,
    DateTime? sessionStart,
    List<String>? viewedContent,
    int? promptsShown,
    Map<String, dynamic>? metadata,
    Map<String, int>? actionAttempts,
    DateTime? lastActivity,
  }) {
    return GuestUserContext(
      sessionId: sessionId ?? this.sessionId,
      sessionStart: sessionStart ?? this.sessionStart,
      viewedContent: viewedContent ?? this.viewedContent,
      promptsShown: promptsShown ?? this.promptsShown,
      metadata: metadata ?? this.metadata,
      actionAttempts: actionAttempts ?? this.actionAttempts,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
  
  /// Add viewed content to the context
  GuestUserContext addViewedContent(String content) {
    final updatedContent = List<String>.from(viewedContent);
    if (!updatedContent.contains(content)) {
      updatedContent.add(content);
    }
    return copyWith(
      viewedContent: updatedContent,
      lastActivity: DateTime.now(),
    );
  }
  
  /// Increment prompts shown counter
  GuestUserContext incrementPrompts() {
    return copyWith(
      promptsShown: promptsShown + 1,
      lastActivity: DateTime.now(),
    );
  }
  
  /// Track action attempt (e.g., join match, hire goalkeeper)
  GuestUserContext trackActionAttempt(String action) {
    final updatedAttempts = Map<String, int>.from(actionAttempts);
    updatedAttempts[action] = (updatedAttempts[action] ?? 0) + 1;
    return copyWith(
      actionAttempts: updatedAttempts,
      lastActivity: DateTime.now(),
    );
  }
  
  /// Check if we should show registration prompt based on engagement
  bool shouldShowPrompt() {
    // Don't over-prompt - max 3 prompts per session
    if (promptsShown >= 3) return false;
    
    // Show prompt if user has viewed some content or attempted actions
    return viewedContent.isNotEmpty || actionAttempts.isNotEmpty;
  }
  
  /// Get engagement score based on user activity
  double get engagementScore {
    double score = 0.0;
    
    // Content viewing contributes to engagement
    score += viewedContent.length * 0.5;
    
    // Action attempts are stronger indicators of engagement
    score += actionAttempts.values.fold(0, (sum, attempts) => sum + attempts) * 2.0;
    
    // Session duration contributes (up to 10 minutes)
    final durationMinutes = sessionDuration.inMinutes.clamp(0, 10);
    score += durationMinutes * 0.1;
    
    return score;
  }
  
  /// Check if user is highly engaged (good candidate for prompt)
  bool get isHighlyEngaged => engagementScore >= 3.0;
  
  /// Get time since last activity
  Duration get timeSinceLastActivity => DateTime.now().difference(lastActivity);
  
  /// Get session duration
  Duration get sessionDuration => DateTime.now().difference(sessionStart);
  
  /// Convert to map for analytics
  Map<String, dynamic> toAnalyticsMap() {
    return {
      'session_id': sessionId,
      'session_start': sessionStart.toIso8601String(),
      'session_duration_minutes': sessionDuration.inMinutes,
      'viewed_content_count': viewedContent.length,
      'viewed_content': viewedContent,
      'prompts_shown': promptsShown,
      'action_attempts': actionAttempts,
      'total_action_attempts': actionAttempts.values.fold(0, (sum, attempts) => sum + attempts),
      'engagement_score': engagementScore,
      'is_highly_engaged': isHighlyEngaged,
      'last_activity': lastActivity.toIso8601String(),
      'time_since_last_activity_minutes': timeSinceLastActivity.inMinutes,
      'metadata': metadata,
    };
  }
}