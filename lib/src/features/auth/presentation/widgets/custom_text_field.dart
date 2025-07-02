import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final int maxLines;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.validator,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 1,
    this.errorText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.shortAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = widget.focusNode?.hasFocus ?? false;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              obscureText: widget.isPassword ? _obscureText : false,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              validator: widget.validator,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              style: AppTheme.bodyLarge,
              cursorColor: AppTheme.accentColor,
              decoration: InputDecoration(
                hintText: widget.hintText,
                labelText: widget.labelText,
                errorText: widget.errorText,
                prefixIcon: widget.prefixIcon != null
                    ? Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Icon(
                          widget.prefixIcon,
                          color: _isFocused
                              ? AppTheme.accentColor
                              : AppTheme.secondaryText,
                          size: 20,
                        ),
                      )
                    : null,
                suffixIcon: widget.isPassword
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _isFocused
                              ? AppTheme.accentColor
                              : AppTheme.secondaryText,
                          size: 20,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: _isFocused
                    ? AppTheme.secondaryBackground
                    : AppTheme.secondaryBackground.withOpacity(0.8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: const BorderSide(
                    color: AppTheme.accentColor,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: const BorderSide(
                    color: AppTheme.errorColor,
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  borderSide: const BorderSide(
                    color: AppTheme.errorColor,
                    width: 2,
                  ),
                ),
                hintStyle: TextStyle(
                  color: AppTheme.secondaryText.withOpacity(0.7),
                  fontSize: 14,
                ),
                labelStyle: TextStyle(
                  color: _isFocused
                      ? AppTheme.accentColor
                      : AppTheme.secondaryText,
                  fontSize: 16,
                ),
                errorStyle: const TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget especializado para email
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final String? errorText;

  const EmailTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      hintText: 'Digite o seu email',
      labelText: 'Email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      validator: validator,
      errorText: errorText,
    );
  }
}

// Widget especializado para password
class PasswordTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final String? errorText;
  final String hintText;
  final String labelText;

  const PasswordTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.errorText,
    this.hintText = 'Digite a sua palavra-passe',
    this.labelText = 'Palavra-passe',
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: Icons.lock_outline,
      isPassword: true,
      textInputAction: TextInputAction.done,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      validator: validator,
      errorText: errorText,
    );
  }
}

// Widget especializado para nome
class NameTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final String? errorText;

  const NameTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      hintText: 'Digite o seu nome completo',
      labelText: 'Nome',
      prefixIcon: Icons.person_outline,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      validator: validator,
      errorText: errorText,
    );
  }
}
