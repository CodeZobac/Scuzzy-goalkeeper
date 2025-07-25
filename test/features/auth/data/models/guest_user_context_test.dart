import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/data/models/guest_user_context.dart';

void main() {
  group('GuestUserContext', () {
    late GuestUserContext context;

    setUp(() {
      context = GuestUserContext.create();
    });

    group('Creation and Basic Properties', () {
      test('should create context with valid session ID and start time', () {
        expect(context.sessionId.startsWith('guest_'), true);
        expect(context.sessionStart.isBefore(DateTime.now().add(const Duration(seconds: 1))), true);
        expect(context.viewedContent, isEmpty);
        expect(context.promptsShown, 0);
        expect(context.actionAttempts, isEmpty);
      });

      test('should set last activity to session start initially', () {
        expect(context.lastActivity, context.sessionStart);
      });
    });

    group('Content Tracking', () {
      test('should add viewed content', () {
        final updated = context.addViewedContent('announcement_123');
        
        expect(updated.viewedContent.length, 1);
        expect(updated.viewedContent.contains('announcement_123'), true);
        expect(updated.lastActivity.isAfter(context.lastActivity), true);
      });

      test('should not duplicate viewed content', () {
        final updated = context
            .addViewedContent('announcement_123')
            .addViewedContent('announcement_123');
        
        expect(updated.viewedContent.length, 1);
        expect(updated.viewedContent.contains('announcement_123'), true);
      });

      test('should track multiple different content items', () {
        final updated = context
            .addViewedContent('announcement_123')
            .addViewedContent('map_field_456')
            .addViewedContent('profile_page');
        
        expect(updated.viewedContent.length, 3);
        expect(updated.viewedContent.contains('announcement_123'), true);
        expect(updated.viewedContent.contains('map_field_456'), true);
        expect(updated.viewedContent.contains('profile_page'), true);
      });
    });

    group('Prompt Tracking', () {
      test('should increment prompts shown', () {
        final updated = context.incrementPrompts();
        
        expect(updated.promptsShown, 1);
        expect(updated.lastActivity.isAfter(context.lastActivity), true);
      });

      test('should track multiple prompts', () {
        final updated = context
            .incrementPrompts()
            .incrementPrompts()
            .incrementPrompts();
        
        expect(updated.promptsShown, 3);
      });
    });

    group('Action Attempt Tracking', () {
      test('should track action attempts', () {
        final updated = context.trackActionAttempt('join_match');
        
        expect(updated.actionAttempts['join_match'], 1);
        expect(updated.lastActivity.isAfter(context.lastActivity), true);
      });

      test('should increment existing action attempts', () {
        final updated = context
            .trackActionAttempt('join_match')
            .trackActionAttempt('join_match')
            .trackActionAttempt('hire_goalkeeper');
        
        expect(updated.actionAttempts['join_match'], 2);
        expect(updated.actionAttempts['hire_goalkeeper'], 1);
      });
    });

    group('Engagement Scoring', () {
      test('should calculate engagement score based on content views', () {
        final updated = context
            .addViewedContent('announcement_123')
            .addViewedContent('map_field_456');
        
        expect(updated.engagementScore, 1.0); // 2 * 0.5 = 1.0
      });

      test('should weight action attempts higher than content views', () {
        final contentOnly = context
            .addViewedContent('announcement_123')
            .addViewedContent('map_field_456'); // 2 * 0.5 = 1.0
        
        final withActions = context
            .trackActionAttempt('join_match'); // 1 * 2.0 = 2.0
        
        expect(withActions.engagementScore, greaterThan(contentOnly.engagementScore));
      });

      test('should identify highly engaged users', () {
        final highlyEngaged = context
            .addViewedContent('announcement_123')
            .addViewedContent('map_field_456')
            .trackActionAttempt('join_match')
            .trackActionAttempt('hire_goalkeeper'); // Should be >= 3.0
        
        expect(highlyEngaged.isHighlyEngaged, true);
        expect(highlyEngaged.engagementScore, greaterThanOrEqualTo(3.0));
      });

      test('should not identify casual users as highly engaged', () {
        final casual = context.addViewedContent('announcement_123'); // 0.5
        
        expect(casual.isHighlyEngaged, false);
        expect(casual.engagementScore, lessThan(3.0));
      });
    });

    group('Prompt Decision Logic', () {
      test('should not show prompt for users with no engagement', () {
        expect(context.shouldShowPrompt(), false);
      });

      test('should show prompt for users with content views', () {
        final withContent = context.addViewedContent('announcement_123');
        expect(withContent.shouldShowPrompt(), true);
      });

      test('should show prompt for users with action attempts', () {
        final withActions = context.trackActionAttempt('join_match');
        expect(withActions.shouldShowPrompt(), true);
      });

      test('should not show prompt after 3 prompts shown', () {
        final withManyPrompts = context
            .addViewedContent('announcement_123')
            .incrementPrompts()
            .incrementPrompts()
            .incrementPrompts(); // 3 prompts
        
        expect(withManyPrompts.shouldShowPrompt(), false);
      });
    });

    group('Time Tracking', () {
      test('should calculate session duration', () {
        // Create context with past start time
        final pastTime = DateTime.now().subtract(const Duration(minutes: 5));
        final pastContext = context.copyWith(sessionStart: pastTime);
        
        expect(pastContext.sessionDuration.inMinutes, greaterThanOrEqualTo(4));
        expect(pastContext.sessionDuration.inMinutes, lessThanOrEqualTo(6));
      });

      test('should track time since last activity', () {
        final pastActivity = DateTime.now().subtract(const Duration(minutes: 3));
        final contextWithPastActivity = context.copyWith(lastActivity: pastActivity);
        
        expect(contextWithPastActivity.timeSinceLastActivity.inMinutes, 
               greaterThanOrEqualTo(2));
        expect(contextWithPastActivity.timeSinceLastActivity.inMinutes, 
               lessThanOrEqualTo(4));
      });
    });

    group('Analytics Data', () {
      test('should convert to analytics map with all relevant data', () {
        final complexContext = context
            .addViewedContent('announcement_123')
            .addViewedContent('map_field_456')
            .trackActionAttempt('join_match')
            .trackActionAttempt('hire_goalkeeper')
            .incrementPrompts();
        
        final analyticsMap = complexContext.toAnalyticsMap();
        
        expect(analyticsMap['session_id'], complexContext.sessionId);
        expect(analyticsMap['viewed_content_count'], 2);
        expect(analyticsMap['viewed_content'], ['announcement_123', 'map_field_456']);
        expect(analyticsMap['prompts_shown'], 1);
        expect(analyticsMap['action_attempts'], {'join_match': 1, 'hire_goalkeeper': 1});
        expect(analyticsMap['total_action_attempts'], 2);
        expect(analyticsMap['engagement_score'], isA<double>());
        expect(analyticsMap['is_highly_engaged'], isA<bool>());
        expect(analyticsMap['session_duration_minutes'], isA<int>());
      });

      test('should include timestamps in analytics map', () {
        final analyticsMap = context.toAnalyticsMap();
        
        expect(analyticsMap['session_start'], isA<String>());
        expect(analyticsMap['last_activity'], isA<String>());
        expect(analyticsMap['time_since_last_activity_minutes'], isA<int>());
      });
    });

    group('Immutability', () {
      test('should not modify original context when adding content', () {
        final original = context;
        final updated = context.addViewedContent('announcement_123');
        
        expect(original.viewedContent.length, 0);
        expect(updated.viewedContent.length, 1);
        expect(original != updated, true);
      });

      test('should not modify original context when incrementing prompts', () {
        final original = context;
        final updated = context.incrementPrompts();
        
        expect(original.promptsShown, 0);
        expect(updated.promptsShown, 1);
        expect(original != updated, true);
      });

      test('should not modify original context when tracking actions', () {
        final original = context;
        final updated = context.trackActionAttempt('join_match');
        
        expect(original.actionAttempts.isEmpty, true);
        expect(updated.actionAttempts['join_match'], 1);
        expect(original != updated, true);
      });
    });

    group('Copy With', () {
      test('should copy with new values', () {
        final newContent = ['new_content'];
        final newAttempts = {'new_action': 1};
        final newActivity = DateTime.now().add(const Duration(minutes: 1));
        
        final updated = context.copyWith(
          viewedContent: newContent,
          promptsShown: 5,
          actionAttempts: newAttempts,
          lastActivity: newActivity,
        );
        
        expect(updated.viewedContent, newContent);
        expect(updated.promptsShown, 5);
        expect(updated.actionAttempts, newAttempts);
        expect(updated.lastActivity, newActivity);
        expect(updated.sessionId, context.sessionId); // Should preserve original
      });

      test('should preserve original values when not specified', () {
        final updated = context.copyWith(promptsShown: 5);
        
        expect(updated.promptsShown, 5);
        expect(updated.sessionId, context.sessionId);
        expect(updated.sessionStart, context.sessionStart);
        expect(updated.viewedContent, context.viewedContent);
      });
    });
  });
}