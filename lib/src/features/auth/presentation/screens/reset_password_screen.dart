import 'package:flutter/material.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/animation_widgets.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_button.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/modern_text_field.dart';
import 'package:goalkeeper/src/features/auth/presentation/widgets/responsive_auth_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ResetPasswordScreen({super.key, required this.onComplete});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onComplete();
          Navigator.of(context).pushReplacementNamed('/signin');
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red,
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
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      title: 'Redefinir Senha',
      subtitle: 'Digite sua nova senha abaixo.',
      child: StaggeredFadeInSlideUp(
        baseDelay: const Duration(milliseconds: 400),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                ModernTextField(
                  hintText: 'Nova Senha',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite sua nova senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ModernButton(
                  text: 'Redefinir Senha',
                  isLoading: _isLoading,
                  onPressed: _handlePasswordReset,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
