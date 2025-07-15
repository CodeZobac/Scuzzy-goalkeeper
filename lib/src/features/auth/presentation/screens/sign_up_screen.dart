import 'package:flutter/material.dart';
import '../widgets/auth_layout.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
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
          backgroundColor: AppTheme.errorColor,
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
            backgroundColor: AppTheme.successColor,
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
            backgroundColor: AppTheme.errorColor,
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
    return AuthLayout(
      title: 'Crie a sua conta',
      subtitle: 'É rápido e fácil',
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de Nome
            FadeInSlideUp(
              delay: const Duration(milliseconds: 100),
              child: NameTextField(
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
            ),

            const SizedBox(height: AppTheme.spacing),

            // Campo de Email
            FadeInSlideUp(
              delay: const Duration(milliseconds: 150),
              child: EmailTextField(
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
            ),

            const SizedBox(height: AppTheme.spacing),

            // Campo de Palavra-passe
            FadeInSlideUp(
              delay: const Duration(milliseconds: 200),
              child: PasswordTextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                validator: _validatePassword,
                errorText: _passwordError,
                hintText: 'Crie uma palavra-passe segura',
                labelText: 'Palavra-passe',
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
            ),

            const SizedBox(height: AppTheme.spacing),

            // Campo de Confirmação de Palavra-passe
            FadeInSlideUp(
              delay: const Duration(milliseconds: 250),
              child: PasswordTextField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                validator: _validateConfirmPassword,
                errorText: _confirmPasswordError,
                hintText: 'Confirme a sua palavra-passe',
                labelText: 'Confirmar palavra-passe',
                onChanged: (value) {
                  if (_confirmPasswordError != null) {
                    setState(() {
                      _confirmPasswordError = null;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: AppTheme.spacing),

            // Checkbox dos Termos e Condições
            FadeInSlideUp(
              delay: const Duration(milliseconds: 300),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    activeColor: AppTheme.accentColor,
                    checkColor: Colors.white,
                    side: const BorderSide(
                      color: AppTheme.secondaryText,
                      width: 2,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: AppTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'Aceito os '),
                            TextSpan(
                              text: 'termos e condições',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.accentColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' e a '),
                            TextSpan(
                              text: 'política de privacidade',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.accentColor,
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

            const SizedBox(height: AppTheme.spacingLarge),

            // Botão de Registo
            FadeInSlideUp(
              delay: const Duration(milliseconds: 350),
              child: PrimaryButton(
                text: 'Registar',
                onPressed: _isLoading ? null : _handleSignUp,
                isLoading: _isLoading,
                icon: Icons.person_add,
              ),
            ),

            const SizedBox(height: AppTheme.spacingLarge),

            // Divisor "OU"
            FadeInSlideUp(
              delay: const Duration(milliseconds: 400),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppTheme.secondaryText.withOpacity(0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OU',
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppTheme.secondaryText.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLarge),

            // Link para Login
            FadeInSlideUp(
              delay: const Duration(milliseconds: 450),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Já tem uma conta? ',
                    style: AppTheme.bodyMedium,
                  ),
                  LinkButton(
                    text: 'Entre',
                    onPressed: _navigateToSignIn,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLarge),
          ],
        ),
      ),
    );
  }
}
