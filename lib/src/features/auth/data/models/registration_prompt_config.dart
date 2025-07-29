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
    message: 'Para participar de partidas e se conectar com outros jogadores, você precisa criar uma conta.',
    context: 'join_match',
  );
  
  /// Configuration for hire goalkeeper prompt
  static const hireGoalkeeper = RegistrationPromptConfig(
    title: 'Contrate um Goleiro!',
    message: 'Para contratar goleiros e gerenciar suas reservas, você precisa criar uma conta.',
    context: 'hire_goalkeeper',
  );
  
  /// Configuration for profile access prompt
  static const profileAccess = RegistrationPromptConfig(
    title: 'Acesse seu Perfil',
    message: 'Crie uma conta para personalizar seu perfil e acessar recursos exclusivos.',
    context: 'profile_access',
  );
  
  /// Configuration for create announcement prompt
  static const createAnnouncement = RegistrationPromptConfig(
    title: 'Crie um Anúncio',
    message: 'Para criar anúncios e organizar partidas, você precisa criar uma conta.',
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
          title: 'Crie sua Conta',
          message: 'Para acessar este recurso, você precisa criar uma conta.',
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