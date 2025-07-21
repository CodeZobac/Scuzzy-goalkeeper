import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final VoidCallback? onToggleObscure;
  final bool showToggle;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool isPassword;

  const ModernTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.onToggleObscure,
    this.showToggle = false,
    this.focusNode,
    this.textInputAction,
    this.errorText,
    this.onChanged,
    this.isPassword = false,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late FocusNode _focusNode;
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _isObscured = widget.isPassword || widget.obscureText;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _focusAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: _focusNode.hasFocus
                      ? AppTheme.primaryGreen.withOpacity(0.15)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: _focusNode.hasFocus ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: _isObscured,
              validator: widget.validator,
              keyboardType: widget.keyboardType,
              focusNode: _focusNode,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Container(
                        margin: const EdgeInsets.only(left: 16, right: 12),
                        child: Icon(widget.prefixIcon, color: AppTheme.textSecondary),
                      )
                    : null,
                suffixIcon: (widget.showToggle || widget.isPassword)
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                          if (widget.onToggleObscure != null) {
                            widget.onToggleObscure!();
                          }
                        },
                        icon: Icon(
                          _isObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  borderSide: BorderSide(
                    color: AppTheme.borderLight,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  borderSide: BorderSide(
                    color: AppTheme.primaryGreen,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  borderSide: const BorderSide(
                    color: AppTheme.errorColor,
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  borderSide: const BorderSide(
                    color: AppTheme.errorColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                errorStyle: AppTheme.bodySmall.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w500,
                ),
                errorText: widget.errorText,
              ),
            ),
          ),
        );
      },
    );
  }
}
