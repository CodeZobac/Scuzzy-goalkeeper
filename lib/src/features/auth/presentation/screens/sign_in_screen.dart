import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/responsive_auth_layout.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../widgets/animation_widgets.dart';
import '../theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../core/error_handling/error_boundary.dart';
import '../../../../core/error_handling/network_error_handler.dart';
import '../../../../core/error_handling/comprehensive_error_handler.dart';
import '../../../../core/logging/error_logger.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {

  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with ErrorHandlingMixin {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, digite o seu email';
    }
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Formato de email inválido';
    }
    
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, digite a sua palavra-passe';
    }
    
    if (value.length < 6) {
      return 'A palavra-passe deve ter pelo menos 6 caracteres';
    }
    
    return null;
  }

  void _handleFieldSubmitted(String value) {
    if (_emailFocusNode.hasFocus) {
      _passwordFocusNode.requestFocus();
    } else if (_passwordFocusNode.hasFocus) {
      _handleSignIn();
    }
  }

  Future<void> _handleSignIn() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use network error handler with retry mechanism
      await NetworkErrorHandler.retryOperation(
        () => _authRepository.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        ),
        context: 'SIGN_IN',
        maxRetries: 2,
        shouldRetry: (error) {
          // Don't retry user credential errors
          if (error is AuthException) {
            return !error.message.toLowerCase().contains('invalid login credentials') &&
                   !error.message.toLowerCase().contains('email not confirmed');
          }
          return true;
        },
      );

      if (mounted) {
        // Log successful sign-in
        ErrorLogger.logInfo(
          'User signed in successfully',
          context: 'AUTH_SUCCESS',
          additionalData: {'email_domain': _emailController.text.split('@').last},
        );
        
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = NetworkErrorHandler.handleAuthError(e);
        
        // Show user-friendly error message
        _showErrorSnackBar(errorMessage);
        
        // Set field-specific errors if applicable
        if (e is AuthException) {
          if (e.message.toLowerCase().contains('invalid login credentials')) {
            setState(() {
              _emailError = 'Credenciais inválidas';
              _passwordError = 'Credenciais inválidas';
            });
          } else if (e.message.toLowerCase().contains('email not confirmed')) {
            setState(() {
              _emailError = 'Email não confirmado';
            });
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.authError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tentar novamente',
          textColor: Colors.white,
          onPressed: _handleSignIn,
        ),
      ),
    );
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushNamed('/signup');
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
        title: '',
        subtitle: '',
        child: SmoothStaggeredAnimation(
          baseDelay: const Duration(milliseconds: 400),
          children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Welcome message with responsive font size
                Center(
                  child: Text(
                    'Aceda à sua conta',
                    style: AppTheme.authHeadingSmall.copyWith(
                      color: AppTheme.authPrimaryGreen,
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 20,
                        tablet: 22,
                        desktop: 24,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 28)),
                
                // Campo de Email
                ModernTextField(
                  hintText: 'Digite o seu email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  validator: _validateEmail,
                  errorText: _emailError,
                  showValidationIcon: true,
                  onChanged: (value) {
                    if (_emailError != null) {
                      setState(() {
                        _emailError = null;
                      });
                    }
                  },
                  onFieldSubmitted: _handleFieldSubmitted,
                ),

                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24)),

                // Campo de Palavra-passe
                ModernTextField(
                  hintText: 'Digite a sua palavra-passe',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  validator: _validatePassword,
                  errorText: _passwordError,
                  showValidationIcon: true,
                  onChanged: (value) {
                    if (_passwordError != null) {
                      setState(() {
                        _passwordError = null;
                      });
                    }
                  },
                  onFieldSubmitted: (_) => _handleSignIn(),
                ),

                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),

                // Link "Esqueceu a palavra-passe?"
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/forgot-password');
                    },
                    child: Text(
                      'Esqueceu a palavra-passe?',
                      style: AppTheme.authLinkText.copyWith(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 32)),

                // Botão de Login
                ModernButton(
                  text: 'Entrar',
                  icon: Icons.login,
                  onPressed: _isLoading ? null : _handleSignIn,
                  isLoading: _isLoading,
                  loadingText: 'Entrando...',
                  width: double.infinity,
                  height: ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: 54.0,
                    tablet: 56.0,
                    desktop: 58.0,
                  ),
                  elevation: 3,
                ),

                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 28)),

                // Divisor "OU"
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                AppTheme.authInputBorder.withOpacity(0.4),
                                AppTheme.authInputBorder.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.authBackground.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.authInputBorder.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'ou',
                          style: AppTheme.authBodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppTheme.authTextSecondary.withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppTheme.authInputBorder.withOpacity(0.6),
                                AppTheme.authInputBorder.withOpacity(0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 28)),

                // Link para Registo
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Ainda não tem conta? ',
                      style: AppTheme.authBodyMedium.copyWith(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                      ),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: _navigateToSignUp,
                            child: Text(
                              'Crie uma aqui',
                              style: AppTheme.authLinkText.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppTheme.authPrimaryGreen,
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 15,
                                  desktop: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
