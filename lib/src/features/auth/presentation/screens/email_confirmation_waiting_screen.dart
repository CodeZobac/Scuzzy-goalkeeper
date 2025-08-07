import 'package:flutter/material.dart';
import '../widgets/responsive_auth_layout.dart';
import '../widgets/modern_button.dart';
import '../widgets/animation_widgets.dart';
import '../theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../../../../shared/utils/responsive_utils.dart';

/// Screen displayed after user signup, prompting them to check their email
/// and confirm their account before they can proceed.
class EmailConfirmationWaitingScreen extends StatefulWidget {
  final String email;
  final String? userId;

  const EmailConfirmationWaitingScreen({
    super.key,
    required this.email,
    this.userId,
  });

  @override
  State<EmailConfirmationWaitingScreen> createState() => _EmailConfirmationWaitingScreenState();
}

class _EmailConfirmationWaitingScreenState extends State<EmailConfirmationWaitingScreen> {
  final AuthRepository _authRepository = AuthRepository();
  bool _isResending = false;
  bool _showResendSuccess = false;

  @override
  void dispose() {
    _authRepository.dispose();
    super.dispose();
  }

  /// Resends the confirmation email
  Future<void> _resendConfirmationEmail() async {
    setState(() {
      _isResending = true;
      _showResendSuccess = false;
    });

    try {
      await _authRepository.resendConfirmationEmail(widget.email);
      
      if (mounted) {
        setState(() {
          _isResending = false;
          _showResendSuccess = true;
        });

        // Hide success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showResendSuccess = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().contains('Azure') || e.toString().contains('email service')
                        ? 'Erro no serviço de email. Tente novamente em alguns minutos.'
                        : 'Falha ao reenviar email. Tente novamente.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.authError,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Navigates to the sign-in screen
  void _navigateToSignIn() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/signin',
      (route) => false,
    );
  }

  /// Opens the email app (if possible)
  void _openEmailApp() {
    // This would typically open the default email app
    // For now, we'll show a helpful message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verifique a sua aplicação de email para o link de confirmação.'),
        backgroundColor: AppTheme.authPrimaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      title: 'Confirme o seu Email',
      subtitle: 'Enviámos um link de confirmação para o seu email',
      showBackButton: false,
      child: StaggeredFadeInSlideUp(
        baseDelay: const Duration(milliseconds: 400),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Email Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.authPrimaryGreen.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.authPrimaryGreen.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 40,
                    color: AppTheme.authPrimaryGreen,
                  ),
                ),
              ),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 32,
                ),
              ),

              // Email Address Display
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    mobile: 16,
                  ),
                  vertical: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    mobile: 12,
                  ),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.authInputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.authInputBorder.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email,
                      size: 20,
                      color: AppTheme.authPrimaryGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.email,
                        style: AppTheme.authBodyMedium.copyWith(
                          color: AppTheme.authTextPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 24,
                ),
              ),

              // Instructions
              Text(
                'Enviámos um email de confirmação para o endereço acima. Clique no link no email para ativar a sua conta.',
                textAlign: TextAlign.center,
                style: AppTheme.authBodyMedium.copyWith(
                  color: AppTheme.authTextSecondary,
                  height: 1.5,
                ),
              ),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 8,
                ),
              ),

              // Additional Instructions
              Text(
                'Não se esqueça de verificar a pasta de spam caso não encontre o email.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.authTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),

              // Resend Success Message
              if (_showResendSuccess) ...[
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    mobile: 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 16,
                    ),
                    vertical: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 12,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.authSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.authSuccess.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppTheme.authSuccess,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Email de confirmação reenviado com sucesso!',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.authSuccess,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 32,
                ),
              ),

              // Primary Action Button - Open Email App
              ModernButton(
                text: 'Abrir Email',
                onPressed: _openEmailApp,
                icon: Icons.email,
                width: double.infinity,
                height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 54.0,
                  tablet: 56.0,
                  desktop: 58.0,
                ),
                elevation: 3,
              ),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 16,
                ),
              ),

              // Secondary Action - Resend Email
              ModernButton(
                text: _isResending ? 'Reenviando...' : 'Reenviar Email',
                onPressed: _isResending ? null : _resendConfirmationEmail,
                icon: _isResending ? null : Icons.refresh,
                width: double.infinity,
                height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 54.0,
                  tablet: 56.0,
                  desktop: 58.0,
                ),
                backgroundColor: AppTheme.authSecondaryGreen,
                textColor: Colors.white,
                isLoading: _isResending,
              ),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 16,
                ),
              ),

              // Tertiary Action - Back to Sign In
              TextButton(
                onPressed: _navigateToSignIn,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 16,
                    ),
                  ),
                ),
                child: Text(
                  'Voltar ao Login',
                  style: AppTheme.authBodyMedium.copyWith(
                    color: AppTheme.authTextSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 16,
                ),
              ),

              // Help Text
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveSpacing(
                    context,
                    mobile: 16,
                  ),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.authInputBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.help_outline,
                          size: 20,
                          color: AppTheme.authTextSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Precisa de ajuda?',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.authTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Se não receber o email em alguns minutos, verifique a sua pasta de spam ou tente reenviar o email.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.authTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
