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
