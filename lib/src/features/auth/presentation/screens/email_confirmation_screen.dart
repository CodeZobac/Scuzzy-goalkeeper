import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/responsive_auth_layout.dart';
import '../widgets/modern_button.dart';
import '../widgets/animation_widgets.dart';
import '../theme/app_theme.dart';
import '../../services/email_confirmation_service.dart';
import '../../../../shared/utils/responsive_utils.dart';

/// Screen for handling email confirmation from redirect URLs
/// 
/// This screen is displayed when users click the confirmation link in their email.
/// It validates the authentication code and completes the email confirmation process.
class EmailConfirmationScreen extends StatefulWidget {
  final String? code;

  const EmailConfirmationScreen({
    super.key,
    this.code,
  });

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  final EmailConfirmationService _confirmationService = EmailConfirmationService();
  
  bool _isLoading = true;
  bool _isConfirmed = false;
  String? _errorMessage;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _handleConfirmation();
  }

  @override
  void dispose() {
    _confirmationService.dispose();
    super.dispose();
  }

  /// Handles the email confirmation process
  Future<void> _handleConfirmation() async {
    if (widget.code == null || widget.code!.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Código de confirmação inválido ou em falta.';
      });
      return;
    }

    try {
      // Validate the confirmation code
      final authCode = await _confirmationService.validateConfirmationCode(widget.code!);
      
      if (authCode == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Código de confirmação inválido, expirado ou já utilizado.';
        });
        return;
      }

      // Store the user ID for potential use
      _userId = authCode.userId;

      // Update the user's email verification status in Supabase Auth
      // Note: This assumes the user is already signed in or we have their session
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser != null && currentUser.id == authCode.userId) {
        // User is signed in and matches the confirmation code
        // The email confirmation is handled automatically by Supabase
        // when the user clicks the confirmation link
        setState(() {
          _isLoading = false;
          _isConfirmed = true;
        });
      } else {
        // User is not signed in or doesn't match
        // This is still a successful confirmation, but they need to sign in
        setState(() {
          _isLoading = false;
          _isConfirmed = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao confirmar email: ${e.toString()}';
      });
    }
  }

  /// Navigates to the sign-in screen
  void _navigateToSignIn() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/signin',
      (route) => false,
    );
  }

  /// Navigates to the home screen
  void _navigateToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      title: 'Confirmação de Email',
      subtitle: 'Verificando a sua confirmação',
      showBackButton: false,
      child: StaggeredFadeInSlideUp(
        baseDelay: const Duration(milliseconds: 400),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLoading
                        ? AppTheme.authPrimaryGreen.withOpacity(0.1)
                        : _isConfirmed
                            ? AppTheme.authSuccess.withOpacity(0.1)
                            : AppTheme.authError.withOpacity(0.1),
                    border: Border.all(
                      color: _isLoading
                          ? AppTheme.authPrimaryGreen.withOpacity(0.3)
                          : _isConfirmed
                              ? AppTheme.authSuccess.withOpacity(0.3)
                              : AppTheme.authError.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.authPrimaryGreen,
                          ),
                        )
                      : Icon(
                          _isConfirmed ? Icons.check_circle : Icons.error,
                          size: 40,
                          color: _isConfirmed
                              ? AppTheme.authSuccess
                              : AppTheme.authError,
                        ),
                ),
              ),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 32,
                ),
              ),

              // Status Message
              Center(
                child: Text(
                  _isLoading
                      ? 'Confirmando email...'
                      : _isConfirmed
                          ? 'Email confirmado com sucesso!'
                          : 'Falha na confirmação',
                  style: AppTheme.authHeadingSmall.copyWith(
                    color: _isLoading
                        ? AppTheme.authTextPrimary
                        : _isConfirmed
                            ? AppTheme.authSuccess
                            : AppTheme.authError,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobile: 20,
                      tablet: 22,
                      desktop: 24,
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  mobile: 16,
                ),
              ),

              // Description
              Center(
                child: Text(
                  _isLoading
                      ? 'Por favor, aguarde enquanto verificamos a sua confirmação de email.'
                      : _isConfirmed
                          ? 'O seu email foi confirmado com sucesso. Pode agora iniciar sessão na sua conta.'
                          : _errorMessage ?? 'Ocorreu um erro durante a confirmação.',
                  textAlign: TextAlign.center,
                  style: AppTheme.authBodyMedium.copyWith(
                    color: AppTheme.authTextSecondary,
                    height: 1.5,
                  ),
                ),
              ),

              if (!_isLoading) ...[
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    mobile: 40,
                  ),
                ),

                // Action Buttons
                if (_isConfirmed) ...[
                  // Success - Navigate to sign in or home
                  ModernButton(
                    text: 'Iniciar Sessão',
                    onPressed: _navigateToSignIn,
                    icon: Icons.login,
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

                  ModernButton(
                    text: 'Ir para Início',
                    onPressed: _navigateToHome,
                    width: double.infinity,
                    height: ResponsiveUtils.getResponsiveValue(
                      context,
                      mobile: 54.0,
                      tablet: 56.0,
                      desktop: 58.0,
                    ),
                    backgroundColor: AppTheme.authSecondaryGreen,
                    textColor: Colors.white,
                  ),
                ] else ...[
                  // Error - Navigate to sign in
                  ModernButton(
                    text: 'Voltar ao Login',
                    onPressed: _navigateToSignIn,
                    icon: Icons.arrow_back,
                    width: double.infinity,
                    height: ResponsiveUtils.getResponsiveValue(
                      context,
                      mobile: 54.0,
                      tablet: 56.0,
                      desktop: 58.0,
                    ),
                    backgroundColor: AppTheme.authSecondaryGreen,
                    textColor: Colors.white,
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}