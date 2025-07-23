import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/presentation/theme/app_theme.dart';

/// Enhanced user marker with smooth animations and better visual feedback
class UserMarker extends StatefulWidget {
  final String? imageUrl;
  final bool isSelected;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final String? userName;
  final bool isOnline;

  const UserMarker({
    Key? key,
    this.imageUrl,
    this.isSelected = false,
    this.isCurrentUser = false,
    this.onTap,
    this.userName,
    this.isOnline = true,
  }) : super(key: key);

  @override
  State<UserMarker> createState() => _UserMarkerState();
}

class _UserMarkerState extends State<UserMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isCurrentUser) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(UserMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else if (!widget.isCurrentUser) {
        _animationController.reverse();
      }
    }

    if (widget.isCurrentUser != oldWidget.isCurrentUser) {
      if (widget.isCurrentUser) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.isSelected ? 20.0 : 16.0;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Semantics(
        label: _buildSemanticLabel(),
        button: widget.onTap != null,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final scale = widget.isCurrentUser 
                ? _pulseAnimation.value 
                : _scaleAnimation.value;
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: effectiveRadius * 2,
                height: effectiveRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getBorderColor().withOpacity(0.4),
                      blurRadius: widget.isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Main avatar
                    CircleAvatar(
                      radius: effectiveRadius,
                      backgroundColor: _getBackgroundColor(),
                      backgroundImage: widget.imageUrl != null 
                          ? CachedNetworkImageProvider(widget.imageUrl!) 
                          : null,
                      child: widget.imageUrl == null
                          ? Icon(
                              Icons.person,
                              color: Colors.white,
                              size: effectiveRadius,
                            )
                          : null,
                    ),
                    
                    // Border ring
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getBorderColor(),
                            width: widget.isSelected ? 3 : 2,
                          ),
                        ),
                      ),
                    ),
                    
                    // Online status indicator
                    if (widget.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    
                    // Current user indicator
                    if (widget.isCurrentUser)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (!widget.isOnline) {
      return Colors.grey.shade400;
    }
    
    if (widget.isCurrentUser) {
      return const Color(0xFF2196F3);
    }
    
    return AppTheme.primaryBackground;
  }

  Color _getBorderColor() {
    if (!widget.isOnline) {
      return Colors.grey.shade600;
    }
    
    if (widget.isCurrentUser) {
      return const Color(0xFF2196F3);
    }
    
    if (widget.isSelected) {
      return const Color(0xFF1E88E5);
    }
    
    return Colors.white;
  }

  String _buildSemanticLabel() {
    final baseLabel = widget.isCurrentUser ? 'Your location' : 'User marker';
    final statusLabel = widget.isOnline ? 'online' : 'offline';
    final selectionLabel = widget.isSelected ? 'selected' : 'unselected';
    
    String userInfo = '';
    if (widget.userName != null) {
      userInfo = ', user: ${widget.userName}';
    }
    
    return '$baseLabel, $statusLabel, $selectionLabel$userInfo';
  }
}

/// Legacy UserMarker for backward compatibility
class LegacyUserMarker extends StatelessWidget {
  final String? imageUrl;

  const LegacyUserMarker({
    Key? key,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.primaryBackground,
      backgroundImage:
          imageUrl != null ? CachedNetworkImageProvider(imageUrl!) : null,
      child: imageUrl == null
          ? const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            )
          : null,
    );
  }
}
