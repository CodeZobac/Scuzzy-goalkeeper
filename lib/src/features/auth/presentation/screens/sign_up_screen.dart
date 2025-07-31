import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/responsive_auth_layout.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../widgets/animation_widgets.dart';
import '../theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../../../../shared/utils/responsive_utils.dart';

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
  bool _acceptTerms = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

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
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, digite o seu nome';
    }

    if (value.length < 2) {
      return 'O nome deve ter pelo menos 2 caracteres';
    }

    if (value.length > 50) {
      return 'O nome deve ter no máximo 50 caracteres';
    }

    return null;
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
      return 'Por favor, digite uma palavra-passe';
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
      return 'Por favor, confirme a sua palavra-passe';
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
          content: Text('Por favor, aceite os termos e condições'),
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
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conta criada com sucesso! Inicie sessão para continuar.',
            ),
            backgroundColor: AppTheme.authSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pushReplacementNamed('/signin');
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Sign up error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorreu um erro ao criar a conta. Tente novamente.'),
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

  void _navigateToSignIn() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      title: 'Crie a sua conta',
      subtitle: 'Junte-se à nossa comunidade de futebol',
      showBackButton: true,
      child: StaggeredFadeInSlideUp(
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
                    mobile: 28,
                  ),
                ),

                // Campo de Nome
                ModernTextField(
                  hintText: 'Digite o seu nome completo',
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
                    mobile: 20,
                  ),
                ),

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
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                ),

                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    mobile: 20,
                  ),
                ),

                // Campo de Palavra-passe
                ModernTextField(
                  hintText: 'Crie uma palavra-passe segura',
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
                    mobile: 20,
                  ),
                ),

                // Campo de Confirmação de Palavra-passe
                ModernTextField(
                  hintText: 'Confirme a sua palavra-passe',
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
                    mobile: 20,
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
                              color: AppTheme.authPrimaryGreen.withOpacity(0.1),
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
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'termos e condições',
                                        style: AppTheme.authBodyMedium.copyWith(
                                          color: AppTheme.authPrimaryGreen,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
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
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'política de privacidade',
                                        style: AppTheme.authBodyMedium.copyWith(
                                          color: AppTheme.authPrimaryGreen,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
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
                    mobile: 24,
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
                    mobile: 28,
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

                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    mobile: 28,
                  ),
                ),

                // Link para Login
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Já tem uma conta? ',
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
                            onTap: _navigateToSignIn,
                            child: Text(
                              'Entre',
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

                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    mobile: 16,
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
