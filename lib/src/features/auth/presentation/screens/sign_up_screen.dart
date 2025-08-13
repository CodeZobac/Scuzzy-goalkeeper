import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../widgets/responsive_auth_layout.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../widgets/animation_widgets.dart';
import '../theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../core/utils/url_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _showVerificationMessage = false;
  bool _acceptTerms = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  Timer? _emailValidationTimer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _emailValidationTimer?.cancel();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'O nome é obrigatório';
    }

    final trimmedValue = value.trim();
    if (trimmedValue.length < 2) {
      return 'O nome deve ter pelo menos 2 caracteres';
    }

    if (trimmedValue.length > 50) {
      return 'O nome deve ter no máximo 50 caracteres';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'O email é obrigatório';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Formato de email inválido';
    }

    return null;
  }

  Future<void> _validateEmailAvailable(String email) async {
    if (email.trim().isEmpty || _emailError != null) return;
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email.trim())) return;

    try {
      final emailExists = await _authRepository.checkEmailExistsForSignup(email.trim());
      if (mounted) {
        setState(() {
          if (emailExists) {
            _emailError = 'Este email já está registado. Tente fazer login ou use outro email.';
          } else {
            _emailError = null;
          }
        });
      }
    } catch (e) {
      // Silently handle validation errors - don't show to user during typing
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A palavra-passe é obrigatória';
    }

    if (value.length < 8) {
      return 'A palavra-passe deve ter pelo menos 8 caracteres';
    }

    // Verificar se contém pelo menos uma letra
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'A palavra-passe deve conter pelo menos uma letra';
    }

    // Verificar se contém pelo menos um número
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'A palavra-passe deve conter pelo menos um número';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A confirmação da palavra-passe é obrigatória';
    }

    if (value != _passwordController.text) {
      return 'As palavras-passe não coincidem';
    }

    return null;
  }

  Future<void> _handleSignUp() async {
    // Limpar erros anteriores
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    // Validar formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Verificar se os termos foram aceites
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É obrigatório aceitar os termos e condições para continuar'),
          backgroundColor: AppTheme.authError,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _showVerificationMessage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Sign up error: $e');
        String errorMessage = 'Ocorreu um erro ao criar a conta. Tente novamente.';
        
        // Handle specific error messages for Azure email service
        if (e.toString().contains('Este email já está registado')) {
          errorMessage = 'Este email já está registado. Tente fazer login ou use outro email.';
          setState(() {
            _emailError = errorMessage;
          });
        } else if (e.toString().contains('Falha ao enviar email de confirmação')) {
          errorMessage = 'Conta criada, mas falha ao enviar email de confirmação. Tente reenviar o email.';
          // Still show verification message since account was created
          setState(() {
            _showVerificationMessage = true;
          });
          return; // Don't show error snackbar, show success with note
        } else if (e.toString().contains('Azure') || e.toString().contains('email service')) {
          errorMessage = 'Erro no serviço de email. Tente novamente em alguns minutos.';
        }
        
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
                  child: Text(errorMessage),
                ),
              ],
            ),
            backgroundColor: AppTheme.authError,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSignIn() {
    Navigator.of(context).pop();
  }

  Future<void> _resendConfirmationEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.resendConfirmationEmail(_emailController.text.trim());
      
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
                  child: Text('Email de confirmação reenviado com sucesso!'),
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
                  child: Text(errorMessage),
                ),
              ],
            ),
            backgroundColor: AppTheme.authError,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
      title: 'Crie a sua conta',
      subtitle: 'Junte-se à nossa comunidade de futebol',
      showBackButton: true,
      child: SmoothStaggeredAnimation(
        baseDelay: const Duration(milliseconds: 400),
        children: [
          if (_showVerificationMessage)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.authSuccess,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'Email enviado!',
                  style: AppTheme.authHeadingSmall.copyWith(
                    color: AppTheme.authSuccess,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enviámos um email de confirmação para o seu endereço. Por favor, clique no botão de confirmação no email para ativar a sua conta.',
                  textAlign: TextAlign.center,
                  style: AppTheme.authBodyMedium,
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                ModernButton(
                  text: 'Reenviar Email de Confirmação',
                  icon: Icons.refresh,
                  onPressed: _isLoading ? null : _resendConfirmationEmail,
                  isLoading: _isLoading,
                  loadingText: 'Reenviando...',
                  width: double.infinity,
                  height: ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: 56.0,
                    tablet: 58.0,
                    desktop: 60.0,
                  ),
                  backgroundColor: AppTheme.authSecondaryGreen,
                  textColor: Colors.white,
                  elevation: 2,
                ),
                const SizedBox(height: 16),
                ModernButton(
                  text: 'Voltar ao Início de Sessão',
                  icon: Icons.login,
                  onPressed: () {
                    UrlUtils.clearUrlParameters();
                    _navigateToSignIn();
                  },
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
            )
          else
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Welcome message with responsive font size
                    Center(
                    child: Text(
                      'Criar nova conta',
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

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 16,
                    ),
                  ),

                  // Mandatory fields note
                  Center(
                    child: Text(
                      '* Campos obrigatórios',
                      style: AppTheme.authBodyMedium.copyWith(
                        color: AppTheme.authTextSecondary,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 16,
                    ),
                  ),

                  // Campo de Nome (obrigatório)
                  ModernTextField(
                    hintText: 'Digite o seu nome completo *',
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    validator: _validateName,
                    errorText: _nameError,
                    showValidationIcon: true,
                    maxLength: 50,
                    onChanged: (value) {
                      if (_nameError != null) {
                        setState(() {
                          _nameError = null;
                        });
                      }
                    },
                    onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 12,
                    ),
                  ),

                  // Campo de Email (obrigatório)
                  ModernTextField(
                    hintText: 'Digite o seu email *',
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
                      
                      // Debounce email validation
                      _emailValidationTimer?.cancel();
                      _emailValidationTimer = Timer(const Duration(milliseconds: 800), () {
                        _validateEmailAvailable(value);
                      });
                    },
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 12,
                    ),
                  ),

                  // Campo de Palavra-passe (obrigatório)
                  ModernTextField(
                    hintText: 'Crie uma palavra-passe segura *',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
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
                      // Revalidar confirmação de senha se ela já foi preenchida
                      if (_confirmPasswordController.text.isNotEmpty) {
                        _formKey.currentState?.validate();
                      }
                    },
                    onFieldSubmitted: (_) =>
                        _confirmPasswordFocusNode.requestFocus(),
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 12,
                    ),
                  ),

                  // Campo de Confirmação de Palavra-passe (obrigatório)
                  ModernTextField(
                    hintText: 'Confirme a sua palavra-passe *',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
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
                    onFieldSubmitted: (_) => _handleSignUp(),
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 12,
                    ),
                  ),

                  // Checkbox dos Termos e Condições
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _acceptTerms
                          ? AppTheme.authPrimaryGreen.withOpacity(0.05)
                          : AppTheme.authBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _acceptTerms
                            ? AppTheme.authPrimaryGreen.withOpacity(0.3)
                            : AppTheme.authInputBorder,
                        width: _acceptTerms ? 2 : 1,
                      ),
                      boxShadow: _acceptTerms
                          ? [
                              BoxShadow(
                                color:
                                    AppTheme.authPrimaryGreen.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptTerms = !_acceptTerms;
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedScale(
                            scale: _acceptTerms ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptTerms = value ?? false;
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                activeColor: AppTheme.authPrimaryGreen,
                                checkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                side: BorderSide(
                                  color: _acceptTerms
                                      ? AppTheme.authPrimaryGreen
                                      : AppTheme.authTextSecondary.withOpacity(
                                          0.6,
                                        ),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: RichText(
                                text: TextSpan(
                                  style: AppTheme.authBodyMedium.copyWith(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Aceito os '),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () {
                                          // TODO: Show terms and conditions
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Termos e condições em desenvolvimento',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'termos e condições',
                                          style:
                                              AppTheme.authBodyMedium.copyWith(
                                            color: AppTheme.authPrimaryGreen,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppTheme.authPrimaryGreen,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(text: ' e a '),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () {
                                          // TODO: Show privacy policy
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Política de privacidade em desenvolvimento',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'política de privacidade',
                                          style:
                                              AppTheme.authBodyMedium.copyWith(
                                            color: AppTheme.authPrimaryGreen,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppTheme.authPrimaryGreen,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 18,
                    ),
                  ),

                  // Botão de Registo
                  ModernButton(
                    text: 'Registar',
                    onPressed: _isLoading ? null : _handleSignUp,
                    isLoading: _isLoading,
                    loadingText: 'Criando conta...',
                    icon: Icons.person_add,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.authBackground.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppTheme.authInputBorder.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'ou',
                            style: AppTheme.authBodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color:
                                  AppTheme.authTextSecondary.withOpacity(0.8),
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

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 16,
                    ),
                  ),

                  // Link para Login
                  ModernButton(
                    text: 'Voltar ao Login',
                    onPressed: _navigateToSignIn,
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

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      mobile: 8,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
