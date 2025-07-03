import 'package:flutter/material.dart';
import '../widgets/auth_layout.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import '../../data/auth_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {

  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
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

  Future<void> _handleSignIn() async {
    // Limpar erros anteriores
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validar formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepository.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        debugPrint('Sign in error: ${e.message}');
        String errorMessage = 'Ocorreu um erro ao fazer login. Tente novamente.';
        if (e.message.contains('Invalid login credentials')) {
          errorMessage = 'Credenciais inválidas. Verifique o seu email e palavra-passe.';
        } else if (e.message.contains('Email not confirmed')) {
          errorMessage = 'Email não confirmado. Verifique a sua caixa de entrada.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Sign in error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorreu um erro inesperado. Tente novamente.'),
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

  void _navigateToSignUp() {
    Navigator.of(context).pushNamed('/signup');
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Bem-vindo de volta!',
      subtitle: 'Faça login para continuar',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de Email
            FadeInSlideUp(
              delay: const Duration(milliseconds: 100),
              child: EmailTextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                validator: _validateEmail,
                errorText: _emailError,
                onChanged: (value) {
                  // Limpar erro quando o usuário começar a digitar
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
                onChanged: (value) {
                  // Limpar erro quando o usuário começar a digitar
                  if (_passwordError != null) {
                    setState(() {
                      _passwordError = null;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: AppTheme.spacingSmall),

            // Link "Esqueceu a palavra-passe?"
            FadeInSlideUp(
              delay: const Duration(milliseconds: 250),
              child: Align(
                alignment: Alignment.centerRight,
                child: LinkButton(
                  text: 'Esqueceu a palavra-passe?',
                  onPressed: () {
                    // TODO: Implementar navegação para recuperação de senha
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        backgroundColor: AppTheme.accentColor,
                      ),
                    );
                  },
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.accentColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLarge),

            // Botão de Login
            FadeInSlideUp(
              delay: const Duration(milliseconds: 300),
              child: PrimaryButton(
                text: 'Entrar',
                onPressed: _isLoading ? null : _handleSignIn,
                isLoading: _isLoading,
                icon: Icons.login,
              ),
            ),

            const SizedBox(height: AppTheme.spacingLarge),

            // Divisor "OU"
            FadeInSlideUp(
              delay: const Duration(milliseconds: 350),
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

            // Link para Registo
            FadeInSlideUp(
              delay: const Duration(milliseconds: 400),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ainda não tem conta? ',
                    style: AppTheme.bodyMedium,
                  ),
                  LinkButton(
                    text: 'Crie uma',
                    onPressed: _navigateToSignUp,
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
