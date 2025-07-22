import 'package:flutter/material.dart';
import '../widgets/modern_auth_layout.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../widgets/animation_widgets.dart';
import '../theme/app_theme.dart';
import '../../data/auth_repository.dart';

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
            content: Text('Conta criada com sucesso! Faça login para continuar.'),
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
    return ModernAuthLayout(
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
              children: [
                const SizedBox(height: 4), // Reduzido
                
                // Campo de Nome
                ModernTextField(
                  hintText: 'Digite o seu nome completo',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  validator: _validateName,
                  errorText: _nameError,
                  onChanged: (value) {
                    if (_nameError != null) {
                      setState(() {
                        _nameError = null;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16), // Reduzido

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
                  onChanged: (value) {
                    if (_emailError != null) {
                      setState(() {
                        _emailError = null;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16), // Reduzido

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
                ),

                const SizedBox(height: 16), // Reduzido

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
                  onChanged: (value) {
                    if (_confirmPasswordError != null) {
                      setState(() {
                        _confirmPasswordError = null;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16), // Reduzido

                // Checkbox dos Termos e Condições
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.authBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.authInputBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          activeColor: AppTheme.authPrimaryGreen,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(
                            color: _acceptTerms 
                                ? AppTheme.authPrimaryGreen 
                                : AppTheme.authTextSecondary,
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: RichText(
                            text: TextSpan(
                              style: AppTheme.authBodyMedium,
                              children: [
                                const TextSpan(text: 'Aceito os '),
                                TextSpan(
                                  text: 'termos e condições',
                                  style: AppTheme.authBodyMedium.copyWith(
                                    color: AppTheme.authPrimaryGreen,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' e a '),
                                TextSpan(
                                  text: 'política de privacidade',
                                  style: AppTheme.authBodyMedium.copyWith(
                                    color: AppTheme.authPrimaryGreen,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
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

                const SizedBox(height: 24), // Reduzido

                // Botão de Registo
                ModernButton(
                  text: 'Registar',
                  onPressed: _isLoading ? null : _handleSignUp,
                  isLoading: _isLoading,
                  icon: Icons.person_add,
                  width: double.infinity,
                ),

                const SizedBox(height: 20), // Reduzido

                // Divisor "OU"
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppTheme.authInputBorder,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OU',
                        style: AppTheme.authBodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppTheme.authInputBorder,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20), // Reduzido

                // Link para Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já tem uma conta? ',
                      style: AppTheme.authBodyMedium,
                    ),
                    ModernLinkButton(
                      text: 'Entre',
                      onPressed: _navigateToSignIn,
                      style: AppTheme.authLinkText.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12), // Reduzido significativamente
              ],
            ),
          ),
        ],
      ),
    );
  }
}
