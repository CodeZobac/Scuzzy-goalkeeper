import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class UserMarker extends StatelessWidget {
  final String? imageUrl;

  const UserMarker({
    Key? key,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.accentColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: AppTheme.primaryBackground,
        backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl!) : null,
        child: imageUrl == null
            ? const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              )
            : null,
      ),
    );
  }
}
