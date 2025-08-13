import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ValueChanged<String>? onFieldSubmitted;
  final bool isPassword;
  final bool showValidationIcon;
  final String? successMessage;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

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
    this.onFieldSubmitted,
    this.isPassword = false,
    this.showValidationIcon = true,
    this.successMessage,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with TickerProviderStateMixin {
  late AnimationController _focusAnimationController;
  late AnimationController _validationAnimationController;
  late AnimationController _shakeAnimationController;
  
  late Animation<double> _focusScaleAnimation;
  late Animation<double> _focusGlowAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _validationIconAnimation;
  late Animation<double> _shakeAnimation;
  
  late FocusNode _focusNode;
  late bool _isObscured;
  bool _hasContent = false;
  bool _isValid = false;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _isObscured = widget.isPassword || widget.obscureText;
    _hasContent = widget.controller?.text.isNotEmpty ?? false;
    
    // If there's an initial error, show validation immediately
    if (widget.errorText != null) {
      _showValidation = true;
    }
    
    // Focus animation controller
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    // Validation animation controller
    _validationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Shake animation controller for errors
    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Focus animations
    _focusScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.01,
    ).animate(CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _focusGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeOut,
    ));

    // Border color animation
    _borderColorAnimation = ColorTween(
      begin: AppTheme.borderLight,
      end: AppTheme.primaryGreen,
    ).animate(CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeOut,
    ));

    // Validation icon animation
    _validationIconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _validationAnimationController,
      curve: Curves.elasticOut,
    ));

    // Shake animation for errors
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeAnimationController,
      curve: Curves.elasticOut,
    ));

    // Focus listener
    _focusNode.addListener(_handleFocusChange);
    
    // Content listener
    widget.controller?.addListener(_handleContentChange);
    
    // Start validation animation if there's an initial error
    if (widget.errorText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validationAnimationController.forward();
      });
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _focusAnimationController.forward();
    } else {
      _focusAnimationController.reverse();
      _validateField();
    }
  }

  void _handleContentChange() {
    final hasContent = widget.controller?.text.isNotEmpty ?? false;
    if (hasContent != _hasContent) {
      setState(() {
        _hasContent = hasContent;
      });
      
      if (hasContent && _showValidation) {
        _validateField();
      }
    }
  }

  void _validateField() {
    if (widget.validator != null && _hasContent) {
      final error = widget.validator!(widget.controller?.text);
      final isValid = error == null;
      
      if (isValid != _isValid) {
        setState(() {
          _isValid = isValid;
          _showValidation = true;
        });
        
        if (isValid) {
          _validationAnimationController.forward();
        } else {
          _validationAnimationController.reverse();
          _triggerShakeAnimation();
        }
      }
    }
  }

  void _triggerShakeAnimation() {
    _shakeAnimationController.reset();
    _shakeAnimationController.forward();
    
    // Haptic feedback for errors
    HapticFeedback.lightImpact();
  }

  @override
  void didUpdateWidget(ModernTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle external error changes
    if (widget.errorText != oldWidget.errorText) {
      final hasError = widget.errorText != null;
      
      if (hasError) {
        // Show error icon and trigger shake animation
        setState(() {
          _showValidation = true;
        });
        _validationAnimationController.forward();
        _triggerShakeAnimation();
      } else if (oldWidget.errorText != null && widget.errorText == null) {
        // Error was cleared, validate the field normally
        _validateField();
      }
    }
  }

  @override
  void dispose() {
    _focusAnimationController.dispose();
    _validationAnimationController.dispose();
    _shakeAnimationController.dispose();
    widget.controller?.removeListener(_handleContentChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  Widget _buildErrorWidget(bool hasError) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: hasError
          ? Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: AppTheme.errorColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.errorText!,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            _focusAnimationController,
            _validationAnimationController,
            _shakeAnimationController,
          ]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _shakeAnimation.value *
                    10 *
                    (1 - _shakeAnimation.value) *
                    ((_shakeAnimationController.value * 4) % 2 == 0 ? 1 : -1),
                0,
              ),
              child: Transform.scale(
                scale: _focusScaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusLarge),
                    boxShadow: [
                      // Main shadow
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      // Focus glow effect
                      if (_focusNode.hasFocus)
                        BoxShadow(
                          color: AppTheme.primaryGreen
                              .withOpacity(0.15 * _focusGlowAnimation.value),
                          blurRadius: 16 * _focusGlowAnimation.value,
                          offset: const Offset(0, 4),
                        ),
                      // Error glow effect
                      if (hasError)
                        BoxShadow(
                          color: AppTheme.errorColor.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      // Success glow effect
                      if (_isValid &&
                          _showValidation &&
                          widget.showValidationIcon &&
                          widget.errorText == null)
                        BoxShadow(
                          color: AppTheme.successColor.withOpacity(
                              0.1 * _validationIconAnimation.value),
                          blurRadius: 10 * _validationIconAnimation.value,
                          offset: const Offset(0, 2),
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
                    enabled: widget.enabled,
                    maxLength: widget.maxLength,
                    inputFormatters: widget.inputFormatters,
                    onChanged: (value) {
                      widget.onChanged?.call(value);
                      if (_showValidation) {
                        _validateField();
                      }
                    },
                    onFieldSubmitted: widget.onFieldSubmitted,
                    style: AppTheme.bodyMedium.copyWith(
                      color: widget.enabled
                          ? AppTheme.textDark
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                      ),
                      prefixIcon: widget.prefixIcon != null
                          ? Container(
                              margin:
                                  const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(
                                widget.prefixIcon,
                                color: _focusNode.hasFocus
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textSecondary,
                                size: 22,
                              ),
                            )
                          : null,
                      suffixIcon: _buildSuffixIcon(),
                      filled: true,
                      fillColor: widget.enabled
                          ? (_focusNode.hasFocus
                              ? AppTheme.surfaceLight
                              : AppTheme.surfaceLight.withOpacity(0.8))
                          : AppTheme.surfaceLight.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusLarge),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusLarge),
                        borderSide: BorderSide(
                          color: widget.errorText != null
                              ? AppTheme.errorColor.withOpacity(0.6)
                              : (_isValid &&
                                      _showValidation &&
                                      widget.showValidationIcon
                                  ? AppTheme.successColor.withOpacity(0.6)
                                  : AppTheme.borderLight),
                          width: (widget.errorText != null ||
                                  (_isValid &&
                                      _showValidation &&
                                      widget.showValidationIcon))
                              ? 2
                              : 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusLarge),
                        borderSide: BorderSide(
                          color:
                              hasError ? AppTheme.errorColor : AppTheme.primaryGreen,
                          width: 2.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusLarge),
                        borderSide: const BorderSide(
                          color: AppTheme.errorColor,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusLarge),
                        borderSide: const BorderSide(
                          color: AppTheme.errorColor,
                          width: 2.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusLarge),
                        borderSide: BorderSide(
                          color: AppTheme.borderLight.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                      errorText: null, // Use custom error widget instead
                      counterStyle: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        _buildErrorWidget(hasError),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    final List<Widget> suffixWidgets = [];

    // Validation icon - consider both internal validation and external errorText
    final hasExternalError = widget.errorText != null;
    final shouldShowValidationIcon = widget.showValidationIcon && 
        (_showValidation && _hasContent || hasExternalError);
    final isFieldValid = _isValid && !hasExternalError;

    if (shouldShowValidationIcon) {
      suffixWidgets.add(
        ScaleTransition(
          scale: _validationIconAnimation,
          child: Icon(
            isFieldValid ? Icons.check_circle : Icons.error,
            color: isFieldValid ? AppTheme.successColor : AppTheme.errorColor,
            size: 20,
          ),
        ),
      );
    }

    // Password toggle
    if (widget.showToggle || widget.isPassword) {
      suffixWidgets.add(
        IconButton(
          onPressed: widget.enabled ? () {
            setState(() {
              _isObscured = !_isObscured;
            });
            widget.onToggleObscure?.call();
            HapticFeedback.selectionClick();
          } : null,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isObscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              key: ValueKey(_isObscured),
              color: _focusNode.hasFocus 
                  ? AppTheme.primaryGreen 
                  : AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ),
      );
    }

    if (suffixWidgets.isEmpty) return null;

    if (suffixWidgets.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: suffixWidgets.first,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: suffixWidgets.map((widget) => 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: widget,
          ),
        ).toList(),
      ),
    );
  }
}
