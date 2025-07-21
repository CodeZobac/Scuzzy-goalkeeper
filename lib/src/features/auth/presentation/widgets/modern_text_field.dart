import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernTextField extends StatefulWidget {
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
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
  final VoidCallback? onSuffixIconTap;

  const ModernTextField({
    super.key,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
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
    this.onSuffixIconTap,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _isFocused = false;
  bool _hasContent = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _borderColorAnimation = ColorTween(
      begin: AppTheme.authInputBorder,
      end: AppTheme.authInputFocused,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    widget.focusNode?.addListener(_onFocusChanged);
    widget.controller?.addListener(_onContentChanged);
    
    // Check initial content
    _hasContent = widget.controller?.text.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChanged);
    widget.controller?.removeListener(_onContentChanged);
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

  void _onContentChanged() {
    final hasContent = widget.controller?.text.isNotEmpty ?? false;
    if (hasContent != _hasContent) {
      setState(() {
        _hasContent = hasContent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTheme.authBodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.authTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.authInputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.errorText != null
                        ? AppTheme.authError
                        : _borderColorAnimation.value ?? AppTheme.authInputBorder,
                    width: _isFocused ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.errorText != null
                          ? AppTheme.authError.withOpacity(0.1)
                          : AppTheme.authPrimaryGreen.withOpacity(_isFocused ? 0.1 : 0.05),
                      blurRadius: _elevationAnimation.value,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  obscureText: widget.isPassword ? _obscureText : false,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  enabled: widget.enabled,
                  maxLines: widget.maxLines,
                  style: AppTheme.authInputText,
                  onChanged: widget.onChanged,
                  validator: widget.validator,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: AppTheme.authHintText,
                    prefixIcon: widget.prefixIcon != null
                        ? Padding(
                            padding: const EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              widget.prefixIcon,
                              color: _isFocused
                                  ? AppTheme.authPrimaryGreen
                                  : AppTheme.authTextSecondary,
                              size: 24,
                            ),
                          )
                        : null,
                    suffixIcon: _buildSuffixIcon(),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.prefixIcon != null ? 8 : 20,
                      vertical: 20,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: AppTheme.authBodyMedium.copyWith(
                color: AppTheme.authError,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          child: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: _isFocused
                ? AppTheme.authPrimaryGreen
                : AppTheme.authTextSecondary,
            size: 24,
          ),
        ),
      );
    }

    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: widget.onSuffixIconTap,
          child: Icon(
            widget.suffixIcon,
            color: _isFocused
                ? AppTheme.authPrimaryGreen
                : AppTheme.authTextSecondary,
            size: 24,
          ),
        ),
      );
    }

    return null;
  }
}

// Specialized text field widgets
class ModernEmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final String? errorText;
  final Function(String)? onChanged;

  const ModernEmailTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.validator,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ModernTextField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      errorText: errorText,
      onChanged: onChanged,
      hintText: 'Digite o seu email',
      labelText: 'Email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
    );
  }
}

class ModernPasswordTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final String? errorText;
  final Function(String)? onChanged;
  final String? hintText;
  final String? labelText;

  const ModernPasswordTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.validator,
    this.errorText,
    this.onChanged,
    this.hintText,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return ModernTextField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      errorText: errorText,
      onChanged: onChanged,
      hintText: hintText ?? 'Digite a sua palavra-passe',
      labelText: labelText ?? 'Palavra-passe',
      prefixIcon: Icons.lock_outline,
      isPassword: true,
      textInputAction: TextInputAction.done,
    );
  }
}

class ModernNameTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final String? errorText;
  final Function(String)? onChanged;

  const ModernNameTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.validator,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ModernTextField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      errorText: errorText,
      onChanged: onChanged,
      hintText: 'Digite o seu nome completo',
      labelText: 'Nome',
      prefixIcon: Icons.person_outline,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
    );
  }
}
