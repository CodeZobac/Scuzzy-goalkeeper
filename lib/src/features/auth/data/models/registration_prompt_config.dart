/// Configuration for registration prompts shown to guest users
class RegistrationPromptConfig {
  final String title;
  final String message;
  final String primaryButtonText;
  final String secondaryButtonText;
  final String context;
  final Map<String, dynamic> metadata;
  
  const RegistrationPromptConfig({
    required this.title,
    required this.message,
    this.primaryButtonText = 'Criar Conta',
    this.secondaryButtonText = 'Agora Não',
    required this.context,
    this.metadata = const {},
  });
  
  /// Configuration for join match prompt
  static const joinMatch = RegistrationPromptConfig(
    title: 'Participe da Partida!',
    message: 'Para participar em partidas e conectar-se com outros jogadores, precisa de criar uma conta.',
    context: 'join_match',
  );
  
  /// Configuration for hire goalkeeper prompt
  static const hireGoalkeeper = RegistrationPromptConfig(
    title: 'Contratar um Guarda-Redes!',
    message: 'Para contratar guarda-redes e gerir as suas reservas, precisa de criar uma conta.',
    context: 'hire_goalkeeper',
  );
  
  /// Configuration for profile access prompt
  static const profileAccess = RegistrationPromptConfig(
    title: 'Aceder ao Seu Perfil',
    message: 'Crie uma conta para personalizar o seu perfil e aceder a recursos exclusivos.',
    context: 'profile_access',
  );
  
  /// Configuration for create announcement prompt
  static const createAnnouncement = RegistrationPromptConfig(
    title: 'Crie um Anúncio',
    message: 'Para criar anúncios e organizar partidas, precisa de criar uma conta.',
    context: 'create_announcement',
  );
  
  /// Get configuration based on context
  static RegistrationPromptConfig forContext(String context) {
    switch (context) {
      case 'join_match':
        return joinMatch;
      case 'hire_goalkeeper':
        return hireGoalkeeper;
      case 'profile_access':
        return profileAccess;
      case 'create_announcement':
        return createAnnouncement;
      default:
        return const RegistrationPromptConfig(
          title: 'Crie a Sua Conta',
          message: 'Para aceder a este recurso, precisa de criar uma conta.',
          context: 'default',
        );
    }
  }
  
  /// Convert to map for analytics
  Map<String, dynamic> toAnalyticsMap() {
    return {
      'title': title,
      'context': context,
      'metadata': metadata,
    };
  }
}