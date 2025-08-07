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
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error_handling/comprehensive_error_handler.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with ErrorHandlingMixin {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isLoading = false;
  String? _emailError;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
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

  Future<void> _handlePasswordReset() async {
    FocusScope.of(context).unfocus();
    
    setState(() {
      _emailError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the updated auth repository method with Azure email service
      await _authRepository.resetPasswordForEmail(_emailController.text);
      setState(() {
        _emailSent = true;
      });
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage;
        if (e.statusCode == '429') {
          errorMessage = 'Muitas tentativas. Por favor, aguarde um pouco antes de tentar novamente.';
        } else if (e.message.contains('Falha ao enviar email de recuperação')) {
          errorMessage = 'Erro no serviço de email. Tente novamente em alguns minutos.';
        } else if (e.message.contains('Este email não está registado')) {
          errorMessage = 'Este email não está registado. Verifique o email ou crie uma conta.';
          setState(() {
            _emailError = errorMessage;
          });
        } else {
          errorMessage = NetworkErrorHandler.handleAuthError(e);
        }
        _showErrorSnackBar(errorMessage);
        
        // Only set email error for email-specific issues
        if (!e.message.contains('Falha ao enviar email de recuperação')) {
          setState(() {
            _emailError = 'Erro ao processar o email';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro inesperado. Tente novamente.';
        if (e.toString().contains('Azure') || e.toString().contains('email service')) {
          errorMessage = 'Erro no serviço de email. Tente novamente em alguns minutos.';
        }
        _showErrorSnackBar(errorMessage);
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _navigateToSignIn() {
    Navigator.of(context).pop();
  }

  Future<void> _resendPasswordResetEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.resendPasswordResetEmail(_emailController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Email de recuperação reenviado com sucesso!'),
                ),
              ],
            ),
            backgroundColor: AppTheme.authSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Falha ao reenviar email. Tente novamente.';
        if (e.toString().contains('Azure') || e.toString().contains('email service')) {
          errorMessage = 'Erro no serviço de email. Tente novamente em alguns minutos.';
        }
        
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
        title: '',
        subtitle: '',
        child: SmoothStaggeredAnimation(
          baseDelay: const Duration(milliseconds: 400),
          children: [
          _emailSent
              ? _buildSuccessView()
              : _buildFormView(),
          ],
        ),
      );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              'Recuperar palavra-passe',
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
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),

          Text(
            'Introduza o seu email para receber um link de recuperação.',
            textAlign: TextAlign.center,
            style: AppTheme.authBodyMedium.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
            ),
          ),

          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 28)),
          
          ModernTextField(
            hintText: 'Digite o seu email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
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
            onFieldSubmitted: (_) => _handlePasswordReset(),
          ),

          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 32)),

          ModernButton(
            text: 'Enviar link de recuperação',
            icon: Icons.send,
            onPressed: _isLoading ? null : _handlePasswordReset,
            isLoading: _isLoading,
            loadingText: 'A enviar...',
            width: double.infinity,
            height: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 54.0,
              tablet: 56.0,
              desktop: 58.0,
            ),
            elevation: 3,
          ),

          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24)),

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

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppTheme.authPrimaryGreen,
          size: 80,
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24)),
        Center(
          child: Text(
            'Email enviado!',
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
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),
        Text(
          'Enviámos um email de recuperação para o seu endereço. Por favor, clique no botão de recuperação no email para redefinir a sua palavra-passe.',
          textAlign: TextAlign.center,
          style: AppTheme.authBodyMedium.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 16,
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24)),
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
            children: [
              Text(
                'Não recebeu o email?',
                style: AppTheme.authBodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifique a pasta de spam ou clique abaixo para reenviar.',
                textAlign: TextAlign.center,
                style: AppTheme.authBodyMedium.copyWith(
                  fontSize: 12,
                  color: AppTheme.authTextSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24)),
        ModernButton(
          text: 'Reenviar Email de Recuperação',
          icon: Icons.refresh,
          onPressed: _isLoading ? null : _resendPasswordResetEmail,
          isLoading: _isLoading,
          loadingText: 'Reenviando...',
          width: double.infinity,
          height: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 54.0,
            tablet: 56.0,
            desktop: 58.0,
          ),
          backgroundColor: AppTheme.authSecondaryGreen,
          textColor: Colors.white,
          elevation: 2,
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),
        ModernButton(
          text: 'Voltar ao Início de Sessão',
          icon: Icons.arrow_back,
          onPressed: _navigateToSignIn,
          width: double.infinity,
          height: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 54.0,
            tablet: 56.0,
            desktop: 58.0,
          ),
          elevation: 3,
        ),
      ],
    );
  }
}
