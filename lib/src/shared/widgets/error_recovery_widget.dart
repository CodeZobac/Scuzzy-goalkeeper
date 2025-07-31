import 'package:flutter/material.dart';
import '../../core/error_handling/error_monitoring_service.dart';
import '../../core/logging/error_logger.dart';
import '../../features/auth/presentation/theme/app_theme.dart';

/// Widget that provides comprehensive error recovery UI with user guidance
class ErrorRecoveryWidget extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;
  final VoidCallback? onContactSupport;
  final IconData? icon;
  final Color? primaryColor;
  final bool showRetryButton;
  final bool showHomeButton;
  final bool showSupportButton;
  final List<String>? troubleshootingSteps;

  const ErrorRecoveryWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onGoHome,
    this.onContactSupport,
    this.icon,
    this.primaryColor,
    this.showRetryButton = true,
    this.showHomeButton = true,
    this.showSupportButton = false,
    this.troubleshootingSteps,
  });

  @override
  State<ErrorRecoveryWidget> createState() => _ErrorRecoveryWidgetState();
}

class _ErrorRecoveryWidgetState extends State<ErrorRecoveryWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? AppTheme.authPrimaryGreen;
    
    return Scaffold(
      backgroundColor: AppTheme.authBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.authBackground,
              Color(0xFFF0F4F3),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(context, primaryColor),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          _buildErrorIcon(primaryColor),
          const SizedBox(height: 32),
          _buildErrorMessage(context),
          const SizedBox(height: 32),
          if (widget.troubleshootingSteps != null) ...[
            _buildTroubleshootingSteps(context),
            const SizedBox(height: 32),
          ],
          _buildActionButtons(context, primaryColor),
          const SizedBox(height: 24),
          _buildSupportInfo(context),
        ],
      ),
    );
  }

  Widget _buildErrorIcon(Color primaryColor) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        widget.icon ?? Icons.error_outline,
        size: 60,
        color: primaryColor,
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.authTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          widget.message,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.authTextSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTroubleshootingSteps(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tente estas soluções:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.troubleshootingSteps!.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        if (widget.showRetryButton && widget.onRetry != null) ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            if (widget.showHomeButton && widget.onGoHome != null) ...[
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: widget.onGoHome,
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Início'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (widget.showHomeButton && widget.showSupportButton) 
              const SizedBox(width: 12),
            if (widget.showSupportButton && widget.onContactSupport != null) ...[
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: widget.onContactSupport,
                    icon: const Icon(Icons.support_agent_outlined),
                    label: const Text('Suporte'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade600,
                      side: BorderSide(color: Colors.orange.shade600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSupportInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            'Se o problema persistir, reinicie o aplicativo ou entre em contato com o suporte.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Specialized error recovery for authentication failures
class AuthErrorRecoveryWidget extends StatelessWidget {
  final String errorType;
  final VoidCallback? onRetry;
  final VoidCallback? onGoToSignUp;

  const AuthErrorRecoveryWidget({
    super.key,
    required this.errorType,
    this.onRetry,
    this.onGoToSignUp,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getErrorConfig(errorType);
    
    return ErrorRecoveryWidget(
      title: config.title,
      message: config.message,
      icon: config.icon,
      primaryColor: AppTheme.authPrimaryGreen,
      troubleshootingSteps: config.troubleshootingSteps,
      onRetry: onRetry,
      onGoHome: () => Navigator.of(context).pushNamedAndRemoveUntil(
        '/signin',
        (route) => false,
      ),
      onContactSupport: config.showSupport ? () {
        // Implement support contact logic
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidade de suporte em desenvolvimento'),
          ),
        );
      } : null,
      showSupportButton: config.showSupport,
    );
  }

  _AuthErrorConfig _getErrorConfig(String errorType) {
    switch (errorType.toLowerCase()) {
      case 'network':
        return _AuthErrorConfig(
          title: 'Problema de Conexão',
          message: 'Não foi possível conectar aos nossos servidores. Verifique a sua conexão com a internet.',
          icon: Icons.wifi_off_outlined,
          troubleshootingSteps: [
            'Verifique se está conectado à internet',
            'Tente alternar entre Wi-Fi e dados móveis',
            'Reinicie o seu roteador se estiver a usar Wi-Fi',
            'Aguarde alguns minutos e tente novamente',
          ],
        );
      case 'credentials':
        return _AuthErrorConfig(
          title: 'Credenciais Inválidas',
          message: 'O email ou palavra-passe estão incorretos. Verifique os dados e tente novamente.',
          icon: Icons.lock_outline,
          troubleshootingSteps: [
            'Verifique se o email está digitado corretamente',
            'Certifique-se de que o Caps Lock não está ativado',
            'Tente redefinir a sua palavra-passe',
            'Use a opção "Esqueceu a palavra-passe?" se necessário',
          ],
        );
      case 'email_not_confirmed':
        return _AuthErrorConfig(
          title: 'Email Não Confirmado',
          message: 'Precisa de confirmar o seu email antes de iniciar sessão. Verifique a sua caixa de entrada.',
          icon: Icons.email_outlined,
          troubleshootingSteps: [
            'Verifique a sua caixa de entrada e pasta de spam',
            'Procure por um email de confirmação',
            'Clique no link de confirmação no email',
            'Aguarde alguns minutos após confirmar',
          ],
          showSupport: true,
        );
      case 'server':
        return _AuthErrorConfig(
          title: 'Problema no Servidor',
          message: 'Nossos servidores estão temporariamente indisponíveis. Tente novamente em alguns instantes.',
          icon: Icons.dns_outlined,
          troubleshootingSteps: [
            'Aguarde alguns minutos e tente novamente',
            'Verifique se há atualizações do aplicativo',
            'Reinicie o aplicativo',
            'Entre em contato com o suporte se persistir',
          ],
          showSupport: true,
        );
      default:
        return _AuthErrorConfig(
          title: 'Erro Inesperado',
          message: 'Ocorreu um erro inesperado. Por favor, tente novamente.',
          icon: Icons.error_outline,
          troubleshootingSteps: [
            'Reinicie o aplicativo',
            'Verifique a sua conexão com a internet',
            'Tente novamente em alguns minutos',
            'Entre em contato com o suporte se necessário',
          ],
          showSupport: true,
        );
    }
  }
}

class _AuthErrorConfig {
  final String title;
  final String message;
  final IconData icon;
  final List<String> troubleshootingSteps;
  final bool showSupport;

  const _AuthErrorConfig({
    required this.title,
    required this.message,
    required this.icon,
    required this.troubleshootingSteps,
    this.showSupport = false,
  });
}

/// Network connectivity error recovery widget
class NetworkErrorRecoveryWidget extends StatefulWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorRecoveryWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  State<NetworkErrorRecoveryWidget> createState() => _NetworkErrorRecoveryWidgetState();
}

class _NetworkErrorRecoveryWidgetState extends State<NetworkErrorRecoveryWidget> {
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    return ErrorRecoveryWidget(
      title: 'Sem Conexão',
      message: widget.customMessage ?? 
          'Não foi possível conectar à internet. Verifique a sua conexão e tente novamente.',
      icon: Icons.wifi_off_outlined,
      primaryColor: Colors.orange.shade600,
      troubleshootingSteps: const [
        'Verifique se o Wi-Fi ou dados móveis estão ativados',
        'Tente alternar entre Wi-Fi e dados móveis',
        'Reinicie o seu roteador se estiver a usar Wi-Fi',
        'Mova-se para uma área com melhor sinal',
      ],
      onRetry: _isRetrying ? null : () async {
        setState(() {
          _isRetrying = true;
        });
        
        // Add a small delay to show loading state
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {
            _isRetrying = false;
          });
          widget.onRetry?.call();
        }
      },
      showHomeButton: false,
      showSupportButton: true,
      onContactSupport: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidade de suporte em desenvolvimento'),
          ),
        );
      },
    );
  }
}