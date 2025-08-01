import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/responsive_auth_layout.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../widgets/animation_widgets.dart';
import '../theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_state_provider.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../core/error_handling/error_boundary.dart';
import '../../../../core/error_handling/network_error_handler.dart';
import '../../../../core/error_handling/comprehensive_error_handler.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/state/password_reset_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> 
    with ErrorHandlingMixin, TickerProviderStateMixin {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _passwordResetSuccessful = false;
  bool _isValidSession = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    // Start animations and check session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _checkPasswordRecoverySession();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  /// Check if the current session is valid for password recovery
  void _checkPasswordRecoverySession() {
    final authProvider = context.read<AuthStateProvider>();
    
    // Clear any existing guest context since we're in a password recovery flow
    if (authProvider.isGuest) {
      authProvider.clearGuestContext();
    }

    // ALWAYS set password recovery mode when on this screen
    // This prevents automatic redirects
    authProvider.handlePasswordRecoveryMode();

    // Check if we have a current session - this indicates we came from a password reset link
    final currentSession = Supabase.instance.client.auth.currentSession;
    
    // Check URL for password reset context
    final currentUrl = Uri.base;
    final hasResetPasswordFragment = currentUrl.fragment.contains('reset-password');
    final hasSupabaseAuthCode = currentUrl.queryParameters.containsKey('code') ||
                              currentUrl.fragment.contains('access_token=');
    
    print('=== RESET SCREEN DEBUG ===');
    print('Has session: ${currentSession != null}');
    print('Has reset fragment: $hasResetPasswordFragment');
    print('Has auth code: $hasSupabaseAuthCode');
    print('URL: ${currentUrl.toString()}');
    print('=== END RESET DEBUG ===');
    
    // If we have a session OR we're on a reset URL, this is valid
    if (currentSession != null || hasResetPasswordFragment) {
      setState(() {
        _isValidSession = true;
      });
      
      ErrorLogger.logInfo(
        'Password recovery session detected on reset screen',
        context: 'PASSWORD_RESET_SCREEN_VALID',
        additionalData: {
          'session_valid': true,
          'has_session': currentSession != null,
          'has_reset_fragment': hasResetPasswordFragment,
          'has_auth_code': hasSupabaseAuthCode,
        },
      );
      return;
    }

    // Listen for password recovery events (for cases where session is created after this check)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() {
          _isValidSession = true;
        });
        
        authProvider.handlePasswordRecoveryMode();
        
        ErrorLogger.logInfo(
          'Password recovery event received',
          context: 'PASSWORD_RESET',
          additionalData: {'session_valid': true},
        );
      }
    });

    // If no session exists, show invalid session view
    if (currentSession == null) {
      setState(() {
        _isValidSession = false;
      });
      
      ErrorLogger.logInfo(
        'No session found for password recovery',
        context: 'PASSWORD_RESET',
        additionalData: {'session_valid': false},
      );
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, digite a nova palavra-passe';
    }
    
    if (value.length < 8) {
      return 'A palavra-passe deve ter pelo menos 8 caracteres';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'A palavra-passe deve conter pelo menos uma letra minúscula, uma maiúscula e um número';
    }
    
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, confirme a palavra-passe';
    }
    
    if (value != _passwordController.text) {
      return 'As palavras-passe não coincidem';
    }
    
    return null;
  }

  Future<void> _handlePasswordUpdate() async {
    FocusScope.of(context).unfocus();
    
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isValidSession) {
      _showErrorSnackBar('Sessão de recuperação inválida. Por favor, clique no link no email novamente.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.updatePassword(_passwordController.text);
      
      setState(() {
        _passwordResetSuccessful = true;
      });

      // Log successful password reset
      ErrorLogger.logInfo(
        'Password reset completed successfully',
        context: 'PASSWORD_RESET_SUCCESS',
      );

      // Clear any guest state that might exist
      final authProvider = context.read<AuthStateProvider>();
      authProvider.clearGuestContext();
      
      // Clear password recovery mode flag to allow normal navigation
      authProvider.clearPasswordRecoveryMode();
      
      // Sign out the user after successful password reset
      // This ensures they need to sign in with their new password
      await Supabase.instance.client.auth.signOut();
      
      // Clear the global password reset flag
      PasswordResetState.clear();

    } on AuthException catch (e) {
      ErrorLogger.logError(
        e,
        StackTrace.current,
        context: 'PASSWORD_RESET_ERROR',
        severity: ErrorSeverity.error,
        additionalData: {'error_code': e.statusCode},
      );

      if (mounted) {
        String errorMessage;
        if (e.statusCode == '422') {
          errorMessage = 'Palavra-passe muito fraca. Por favor, escolha uma palavra-passe mais forte.';
        } else {
          errorMessage = NetworkErrorHandler.handleAuthError(e);
        }
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      ErrorLogger.logError(
        e is Exception ? e : Exception(e.toString()),
        StackTrace.current,
        context: 'PASSWORD_RESET_ERROR',
        severity: ErrorSeverity.error,
      );

      if (mounted) {
        _showErrorSnackBar('Erro inesperado. Por favor, tente novamente.');
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
            const Icon(
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
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Tentar novamente',
          textColor: Colors.white,
          onPressed: _handlePasswordUpdate,
        ),
      ),
    );
  }

  void _navigateToSignIn() {
    // Clear the password reset state flags first
    final authProvider = context.read<AuthStateProvider>();
    authProvider.clearPasswordRecoveryMode();
    PasswordResetState.clear();
    
    // Set a flag to indicate we're coming from password reset completion
    // This will prevent the popover from showing again
    authProvider.setPasswordResetCompleted();
    
    // Navigate to signin
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/signin',
      (route) => false,
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.authBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ResponsiveAuthLayout(
              title: '',
              subtitle: '',
              child: StaggeredFadeInSlideUp(
                baseDelay: const Duration(milliseconds: 400),
                children: [
                  _passwordResetSuccessful
                      ? _buildSuccessView()
                      : _isValidSession
                          ? _buildPasswordResetForm()
                          : _buildInvalidSessionView(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.authPrimaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.authPrimaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24)),

          Center(
            child: Text(
              'Redefinir Palavra-passe',
              style: AppTheme.authHeadingSmall.copyWith(
                color: AppTheme.authPrimaryGreen,
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 22,
                  tablet: 24,
                  desktop: 26,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12)),

          Text(
            'Introduza a sua nova palavra-passe para completar a recuperação.',
            textAlign: TextAlign.center,
            style: AppTheme.authBodyMedium.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
              height: 1.5,
            ),
          ),

          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 32)),

          // New Password Field
          ModernTextField(
            hintText: 'Nova palavra-passe',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            isPassword: true,
            showToggle: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
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
            onFieldSubmitted: (_) {
              _confirmPasswordFocusNode.requestFocus();
            },
          ),

          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20)),

          // Confirm Password Field
          ModernTextField(
            hintText: 'Confirmar palavra-passe',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            isPassword: true,
            showToggle: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            validator: _validateConfirmPassword,
            errorText: _confirmPasswordError,
            showValidationIcon: true,
            onChanged: (value) {
              if (_confirmPasswordError != null) {
                setState(() {
                  _confirmPasswordError = null;
                });
              }
            },
            onFieldSubmitted: (_) => _handlePasswordUpdate(),
          ),

          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8)),

          // Password requirements
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.authCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.authInputBorder.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requisitos da palavra-passe:',
                  style: AppTheme.authBodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPasswordRequirement(
                  'Pelo menos 8 caracteres',
                  _passwordController.text.length >= 8,
                ),
                _buildPasswordRequirement(
                  'Pelo menos uma letra minúscula',
                  RegExp(r'[a-z]').hasMatch(_passwordController.text),
                ),
                _buildPasswordRequirement(
                  'Pelo menos uma letra maiúscula',
                  RegExp(r'[A-Z]').hasMatch(_passwordController.text),
                ),
                _buildPasswordRequirement(
                  'Pelo menos um número',
                  RegExp(r'\d').hasMatch(_passwordController.text),
                ),
              ],
            ),
          ),

          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 32)),

          // Update Password Button
          ModernButton(
            text: 'Redefinir Palavra-passe',
            icon: Icons.check_circle_outline,
            onPressed: _isLoading ? null : _handlePasswordUpdate,
            isLoading: _isLoading,
            loadingText: 'A redefinir...',
            width: double.infinity,
            height: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 56.0,
              tablet: 58.0,
              desktop: 60.0,
            ),
            elevation: 3,
          ),

          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24)),

          // Back to Sign In
          TextButton(
            onPressed: _navigateToSignIn,
            child: Text(
              'Voltar ao Início de Sessão',
              style: AppTheme.authLinkText.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String requirement, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? AppTheme.authSuccess : AppTheme.authTextSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            requirement,
            style: AppTheme.bodySmall.copyWith(
              color: isMet ? AppTheme.authSuccess : AppTheme.authTextSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success Icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.authSuccess,
                AppTheme.authSuccess.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.authSuccess.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 60,
          ),
        ),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 32)),

        Center(
          child: Text(
            'Palavra-passe redefinida!',
            style: AppTheme.authHeadingSmall.copyWith(
              color: AppTheme.authSuccess,
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 22,
                tablet: 24,
                desktop: 26,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),

        Text(
          'A sua palavra-passe foi redefinida com sucesso. Agora pode iniciar sessão com a nova palavra-passe.',
          textAlign: TextAlign.center,
          style: AppTheme.authBodyMedium.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 16,
            ),
            height: 1.5,
          ),
        ),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 40)),

        ModernButton(
          text: 'Iniciar Sessão',
          icon: Icons.login,
          onPressed: _navigateToSignIn,
          width: double.infinity,
          height: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 56.0,
            tablet: 58.0,
            desktop: 60.0,
          ),
          elevation: 3,
        ),
      ],
    );
  }

  Widget _buildInvalidSessionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Error Icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.authError,
                AppTheme.authError.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.authError.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 60,
          ),
        ),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 32)),

        Center(
          child: Text(
            'Link Inválido',
            style: AppTheme.authHeadingSmall.copyWith(
              color: AppTheme.authError,
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 22,
                tablet: 24,
                desktop: 26,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),

        Text(
          'Este link de recuperação de palavra-passe é inválido ou expirou. Por favor, solicite um novo link.',
          textAlign: TextAlign.center,
          style: AppTheme.authBodyMedium.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 16,
            ),
            height: 1.5,
          ),
        ),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 40)),

        ModernButton(
          text: 'Solicitar Novo Link',
          icon: Icons.refresh,
          onPressed: () => Navigator.of(context).pushReplacementNamed('/forgot-password'),
          width: double.infinity,
          height: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 56.0,
            tablet: 58.0,
            desktop: 60.0,
          ),
          elevation: 3,
        ),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),

        TextButton(
          onPressed: _navigateToSignIn,
          child: Text(
            'Voltar ao Início de Sessão',
            style: AppTheme.authLinkText.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
