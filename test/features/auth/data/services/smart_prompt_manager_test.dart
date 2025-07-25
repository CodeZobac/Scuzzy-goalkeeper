import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/data/services/smart_prompt_manager.dart';
import 'package:goalkeeper/src/features/auth/data/models/guest_user_context.dart';
import 'package:goalkeeper/src/features/auth/data/models/registration_prompt_config.dart';

void main() {
  group('SmartPromptManager', () {
    late SmartPromptManager promptManager;
    late GuestUserContext guestContext;

    setUp(() {
      promptManager = SmartPromptManager.instance;
      promptManager.resetPromptHistory();
      guestContext = GuestUserContext.create();
    });

    tearDown(() {
      promptManager.resetPromptHistory();
    });

    group('Basic Prompt Logic', () {
      test('should allow prompt for engaged user with no history', () {
        // Create context with past start time to pass timing check
        final pastTime = DateTime.now().subtract(const Duration(minutes: 2));
        final engagedContext = guestContext
            .copyWith(sessionStart: pastTime)
            .addViewedContent('announcement_123')
            .addViewedContent('map_field_456');
        
        final shouldShow = promptManager.shouldShowPrompt('join_match', engagedContext);
        expect(shouldShow, true);
      });

      test('should not allow prompt for user with no engagement', () {
        final shouldShow = promptManager.shouldShowPrompt('join_match', guestContext);
        expect(shouldShow, false);
      });

      test('should not allow prompt if session limit exceeded', () {
        final contextWithManyPrompts = guestContext
            .addViewedContent('announcement_123')
            .incrementPrompts()
            .incrementPrompts()
            .incrementPrompts()
            .incrementPrompts(); // 4 prompts shown
        
        final shouldShow = promptManager.shouldShowPrompt('join_match', contextWithManyPrompts);
        expect(shouldShow, false);
      });
    });

    group('Context-Specific Frequency Limits', () {
      test('should not allow same prompt type too frequently', () {
        // Create context with past start time to pass timing check
        final pastTime = DateTime.now().subtract(const Duration(minutes: 2));
        final engagedContext = guestContext
            .copyWith(sessionStart: pastTime)
            .addViewedContent('announcement_123');
        
        // First prompt should be allowed
        expect(promptManager.shouldShowPrompt('join_match', engagedContext), true);
        promptManager.recordPromptShown('join_match');
        
        // Second prompt should be allowed
        expect(promptManager.shouldShowPrompt('join_match', engagedContext), true);
        promptManager.recordPromptShown('join_match');
        
        // Third prompt within same hour should be blocked
        expect(promptManager.shouldShowPrompt('join_match', engagedContext), false);
      });

      test('should allow different prompt types', () {
        // Create context with past start time to pass timing check
        final pastTime = DateTime.now().subtract(const Duration(minutes: 2));
        final engagedContext = guestContext
            .copyWith(sessionStart: pastTime)
            .addViewedContent('announcement_123');
        
        promptManager.recordPromptShown('join_match');
        promptManager.recordPromptShown('join_match');
        
        // Same type should be blocked
        expect(promptManager.shouldShowPrompt('join_match', engagedContext), false);
        
        // Different type should be allowed
        expect(promptManager.shouldShowPrompt('hire_goalkeeper', engagedContext), true);
      });
    });

    group('User Fatigue Detection', () {
      test('should detect prompt fatigue after multiple dismissals', () {
        final engagedContext = guestContext.addViewedContent('announcement_123');
        
        // Dismiss prompt 3 times
        promptManager.recordPromptDismissed('join_match');
        promptManager.recordPromptDismissed('join_match');
        promptManager.recordPromptDismissed('join_match');
        
        final shouldShow = promptManager.shouldShowPrompt('join_match', engagedContext);
        expect(shouldShow, false);
      });

      test('should not affect other prompt types when one type is fatigued', () {
        // Create context with past start time to pass timing check
        final pastTime = DateTime.now().subtract(const Duration(minutes: 2));
        final engagedContext = guestContext
            .copyWith(sessionStart: pastTime)
            .addViewedContent('announcement_123');
        
        // Fatigue one prompt type
        promptManager.recordPromptDismissed('join_match');
        promptManager.recordPromptDismissed('join_match');
        promptManager.recordPromptDismissed('join_match');
        
        // Should block fatigued type
        expect(promptManager.shouldShowPrompt('join_match', engagedContext), false);
        
        // Should allow other types
        expect(promptManager.shouldShowPrompt('hire_goalkeeper', engagedContext), true);
      });
    });

    group('Timing-Based Logic', () {
      test('should not prompt immediately after session start', () {
        final newContext = GuestUserContext.create();
        final contextWithContent = newContext.addViewedContent('announcement_123');
        
        final shouldShow = promptManager.shouldShowPrompt('join_match', contextWithContent);
        expect(shouldShow, false);
      });

      test('should not prompt inactive users', () {
        // Create context with old last activity
        final oldTime = DateTime.now().subtract(const Duration(minutes: 10));
        final inactiveContext = guestContext.copyWith(
          lastActivity: oldTime,
          viewedContent: ['announcement_123'],
        );
        
        final shouldShow = promptManager.shouldShowPrompt('join_match', inactiveContext);
        expect(shouldShow, false);
      });
    });

    group('Engagement-Based Session Limits', () {
      test('should allow more prompts for highly engaged users', () {
        // Create highly engaged context with past start time
        final pastTime = DateTime.now().subtract(const Duration(minutes: 2));
        final highlyEngagedContext = guestContext
            .copyWith(sessionStart: pastTime)
            .addViewedContent('announcement_123')
            .addViewedContent('map_field_456')
            .trackActionAttempt('join_match')
            .trackActionAttempt('hire_goalkeeper')
            .incrementPrompts()
            .incrementPrompts()
            .incrementPrompts(); // 3 prompts shown
        
        expect(highlyEngagedContext.isHighlyEngaged, true);
        
        // Use a different prompt type to avoid context-specific frequency limits
        final shouldShow = promptManager.shouldShowPrompt('hire_goalkeeper', highlyEngagedContext);
        expect(shouldShow, true);
      });

      test('should limit prompts for less engaged users', () {
        // Create moderately engaged context with past start time
        final pastTime = DateTime.now().subtract(const Duration(minutes: 2));
        final moderateContext = guestContext
            .copyWith(sessionStart: pastTime)
            .addViewedContent('announcement_123')
            .addViewedContent('map_field_456')
            .incrementPrompts(); // 1 prompt shown, engagement score should be 1.0
        
        expect(moderateContext.isHighlyEngaged, false);
        expect(moderateContext.engagementScore, greaterThan(1.0)); // 2 * 0.5 + session duration
        
        // Should still allow one more prompt (limit is 2 for low engagement)
        expect(promptManager.shouldShowPrompt('hire_goalkeeper', moderateContext), true);
        
        // But not after 2nd prompt for low engagement users
        final contextWith2Prompts = moderateContext.incrementPrompts();
        expect(promptManager.shouldShowPrompt('profile_access', contextWith2Prompts), false);
      });
    });

    group('Optimal Prompt Configuration', () {
      test('should return enhanced prompt for highly engaged users', () {
        final highlyEngagedContext = guestContext
            .addViewedContent('announcement_123')
            .addViewedContent('map_field_456')
            .trackActionAttempt('join_match')
            .trackActionAttempt('hire_goalkeeper');
        
        final config = promptManager.getOptimalPromptConfig('join_match', highlyEngagedContext);
        
        expect(config.primaryButtonText, 'Vamos Começar!');
        expect(config.metadata['user_engagement'], 'high');
        expect(config.message.contains('interessado em participar'), true);
      });

      test('should return standard prompt for casual users', () {
        final casualContext = guestContext.addViewedContent('announcement_123');
        
        final config = promptManager.getOptimalPromptConfig('join_match', casualContext);
        
        expect(config.primaryButtonText, 'Criar Conta');
        expect(config.secondaryButtonText, 'Continuar Explorando');
        expect(config.metadata['user_engagement'], 'casual');
        expect(config.message.contains('rápido e gratuito'), true);
      });

      test('should customize message based on user activity', () {
        // Create highly engaged context to trigger enhanced message
        final contextWithViews = guestContext
            .addViewedContent('announcement_123')
            .addViewedContent('map_field_456')
            .addViewedContent('profile_page')
            .addViewedContent('another_announcement')
            .trackActionAttempt('join_match'); // This makes it highly engaged
        
        final config = promptManager.getOptimalPromptConfig('join_match', contextWithViews);
        
        // Should get the action-based message since there are action attempts
        expect(config.message.contains('interessado em participar'), true);
      });
    });

    group('Statistics and Analytics', () {
      test('should track prompt statistics', () {
        final engagedContext = guestContext.addViewedContent('announcement_123');
        
        promptManager.recordPromptShown('join_match');
        promptManager.recordPromptShown('join_match');
        promptManager.recordPromptDismissed('join_match');
        
        final stats = promptManager.getPromptStatistics();
        
        expect(stats['join_match']['total_shown'], 2);
        expect(stats['join_match']['total_dismissed'], 1);
        expect(stats['join_match']['dismissal_rate'], 0.5);
      });

      test('should reset prompt history', () {
        promptManager.recordPromptShown('join_match');
        promptManager.recordPromptDismissed('join_match');
        
        expect(promptManager.getPromptStatistics().isNotEmpty, true);
        
        promptManager.resetPromptHistory();
        
        expect(promptManager.getPromptStatistics().isEmpty, true);
      });
    });

    group('Edge Cases', () {
      test('should handle null or empty contexts gracefully', () {
        final emptyContext = GuestUserContext.create();
        
        expect(() => promptManager.shouldShowPrompt('join_match', emptyContext), 
               returnsNormally);
        expect(promptManager.shouldShowPrompt('join_match', emptyContext), false);
      });

      test('should handle unknown prompt contexts', () {
        final engagedContext = guestContext.addViewedContent('announcement_123');
        
        expect(() => promptManager.shouldShowPrompt('unknown_context', engagedContext), 
               returnsNormally);
        
        final config = promptManager.getOptimalPromptConfig('unknown_context', engagedContext);
        expect(config.context, 'default');
      });
    });
  });
}