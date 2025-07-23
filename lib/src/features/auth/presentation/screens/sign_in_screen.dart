import 'package:flutter/material.dart';
import '../widgets/modern_auth_layout.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../widgets/animation_widgets.dart';
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
            backgroundColor: AppTheme.authError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Sign in error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorreu um erro inesperado. Tente novamente.'),
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

  void _navigateToSignUp() {
    Navigator.of(context).pushNamed('/signup');
  }

  @override
  Widget build(BuildContext context) {
    return ModernAuthLayout(
      title: 'Bem-vindo de volta!',
      subtitle: 'Acesse a sua conta para encontrar o guarda-redes perfeito',
      child: StaggeredFadeInSlideUp(
        baseDelay: const Duration(milliseconds: 400),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4), // Reduzido
                
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

                const SizedBox(height: 18), // Reduzido

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
                  onChanged: (value) {
                    if (_passwordError != null) {
                      setState(() {
                        _passwordError = null;
                      });
                    }
                  },
                ),

                const SizedBox(height: 10), // Reduzido

                // Link "Esqueceu a palavra-passe?"
                Align(
                  alignment: Alignment.centerRight,
                  child: ModernLinkButton(
                    text: 'Esqueceu a palavra-passe?',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Funcionalidade em desenvolvimento'),
                          backgroundColor: AppTheme.authPrimaryGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28), // Reduzido

                // Botão de Login
                ModernButton(
                  text: 'Entrar',
                  onPressed: _isLoading ? null : _handleSignIn,
                  isLoading: _isLoading,
                  icon: Icons.login,
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

                // Link para Registo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ainda não tem conta? ',
                      style: AppTheme.authBodyMedium,
                    ),
                    ModernLinkButton(
                      text: 'Crie uma',
                      onPressed: _navigateToSignUp,
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
