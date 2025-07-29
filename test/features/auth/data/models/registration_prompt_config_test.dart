import 'package:flutter_test/flutter_test.dart';
import 'package:goalkeeper/src/features/auth/data/models/registration_prompt_config.dart';

void main() {
  group('RegistrationPromptConfig', () {
    group('Constructor', () {
      test('should create config with required fields', () {
        // Act
        const config = RegistrationPromptConfig(
          title: 'Test Title',
          message: 'Test Message',
          context: 'test_context',
        );
        
        // Assert
        expect(config.title, equals('Test Title'));
        expect(config.message, equals('Test Message'));
        expect(config.context, equals('test_context'));
        expect(config.primaryButtonText, equals('Criar Conta'));
        expect(config.secondaryButtonText, equals('Agora Não'));
        expect(config.metadata, isEmpty);
      });

      test('should create config with custom button texts', () {
        // Act
        const config = RegistrationPromptConfig(
          title: 'Test Title',
          message: 'Test Message',
          context: 'test_context',
          primaryButtonText: 'Custom Primary',
          secondaryButtonText: 'Custom Secondary',
        );
        
        // Assert
        expect(config.primaryButtonText, equals('Custom Primary'));
        expect(config.secondaryButtonText, equals('Custom Secondary'));
      });

      test('should create config with metadata', () {
        // Act
        const config = RegistrationPromptConfig(
          title: 'Test Title',
          message: 'Test Message',
          context: 'test_context',
          metadata: {'key': 'value', 'number': 42},
        );
        
        // Assert
        expect(config.metadata, equals({'key': 'value', 'number': 42}));
      });
    });

    group('Predefined Configurations', () {
      test('should have correct join match configuration', () {
        // Act
        const config = RegistrationPromptConfig.joinMatch;
        
        // Assert
        expect(config.title, equals('Participe da Partida!'));
        expect(config.message, contains('participar de partidas'));
        expect(config.context, equals('join_match'));
        expect(config.primaryButtonText, equals('Criar Conta'));
        expect(config.secondaryButtonText, equals('Agora Não'));
      });

      test('should have correct hire goalkeeper configuration', () {
        // Act
        const config = RegistrationPromptConfig.hireGoalkeeper;
        
        // Assert
        expect(config.title, equals('Contrate um Goleiro!'));
        expect(config.message, contains('contratar goleiros'));
        expect(config.context, equals('hire_goalkeeper'));
        expect(config.primaryButtonText, equals('Criar Conta'));
        expect(config.secondaryButtonText, equals('Agora Não'));
      });

      test('should have correct profile access configuration', () {
        // Act
        const config = RegistrationPromptConfig.profileAccess;
        
        // Assert
        expect(config.title, equals('Acesse seu Perfil'));
        expect(config.message, contains('personalizar seu perfil'));
        expect(config.context, equals('profile_access'));
        expect(config.primaryButtonText, equals('Criar Conta'));
        expect(config.secondaryButtonText, equals('Agora Não'));
      });

      test('should have correct create announcement configuration', () {
        // Act
        const config = RegistrationPromptConfig.createAnnouncement;
        
        // Assert
        expect(config.title, equals('Crie um Anúncio'));
        expect(config.message, contains('criar anúncios'));
        expect(config.context, equals('create_announcement'));
        expect(config.primaryButtonText, equals('Criar Conta'));
        expect(config.secondaryButtonText, equals('Agora Não'));
      });
    });

    group('Context-based Configuration', () {
      test('should return join match config for join_match context', () {
        // Act
        final config = RegistrationPromptConfig.forContext('join_match');
        
        // Assert
        expect(config.title, equals(RegistrationPromptConfig.joinMatch.title));
        expect(config.context, equals('join_match'));
      });

      test('should return hire goalkeeper config for hire_goalkeeper context', () {
        // Act
        final config = RegistrationPromptConfig.forContext('hire_goalkeeper');
        
        // Assert
        expect(config.title, equals(RegistrationPromptConfig.hireGoalkeeper.title));
        expect(config.context, equals('hire_goalkeeper'));
      });

      test('should return profile access config for profile_access context', () {
        // Act
        final config = RegistrationPromptConfig.forContext('profile_access');
        
        // Assert
        expect(config.title, equals(RegistrationPromptConfig.profileAccess.title));
        expect(config.context, equals('profile_access'));
      });

      test('should return create announcement config for create_announcement context', () {
        // Act
        final config = RegistrationPromptConfig.forContext('create_announcement');
        
        // Assert
        expect(config.title, equals(RegistrationPromptConfig.createAnnouncement.title));
        expect(config.context, equals('create_announcement'));
      });

      test('should return default config for unknown context', () {
        // Act
        final config = RegistrationPromptConfig.forContext('unknown_context');
        
        // Assert
        expect(config.title, equals('Crie sua Conta'));
        expect(config.message, contains('Para acessar este recurso'));
        expect(config.context, equals('default'));
        expect(config.primaryButtonText, equals('Criar Conta'));
        expect(config.secondaryButtonText, equals('Agora Não'));
      });
    });

    group('Analytics Conversion', () {
      test('should convert to analytics map with required fields', () {
        // Arrange
        const config = RegistrationPromptConfig(
          title: 'Test Title',
          message: 'Test Message',
          context: 'test_context',
          metadata: {'key': 'value'},
        );
        
        // Act
        final analyticsMap = config.toAnalyticsMap();
        
        // Assert
        expect(analyticsMap['title'], equals('Test Title'));
        expect(analyticsMap['context'], equals('test_context'));
        expect(analyticsMap['metadata'], equals({'key': 'value'}));
      });

      test('should handle empty metadata in analytics conversion', () {
        // Arrange
        const config = RegistrationPromptConfig(
          title: 'Test Title',
          message: 'Test Message',
          context: 'test_context',
        );
        
        // Act
        final analyticsMap = config.toAnalyticsMap();
        
        // Assert
        expect(analyticsMap['metadata'], isEmpty);
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings gracefully', () {
        // Act
        const config = RegistrationPromptConfig(
          title: '',
          message: '',
          context: '',
        );
        
        // Assert
        expect(config.title, isEmpty);
        expect(config.message, isEmpty);
        expect(config.context, isEmpty);
      });

      test('should handle null context in forContext method', () {
        // Act
        final config = RegistrationPromptConfig.forContext('');
        
        // Assert
        expect(config.context, equals('default'));
        expect(config.title, equals('Crie sua Conta'));
      });
    });
  });
}