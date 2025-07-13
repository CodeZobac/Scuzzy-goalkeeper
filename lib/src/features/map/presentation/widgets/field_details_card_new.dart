import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/map_field.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class FieldDetailsCardNew extends StatelessWidget {
  final MapField field;
  final VoidCallback onClose;

  const FieldDetailsCardNew({
    Key? key,
    required this.field,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      elevation: 8,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          color: AppTheme.primaryBackground,
        ),
        child: Row(
          children: [
            // Field Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius),
                bottomLeft: Radius.circular(AppTheme.borderRadius),
              ),
              child: CachedNetworkImage(
                imageUrl: field.photoUrl ?? 'https://via.placeholder.com/150',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            // Field Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      field.name,
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      field.description ?? 'No description available.',
                      style: AppTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.5', // This should come from the field data
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTag('Natural', AppTheme.successColor),
                        const SizedBox(width: 8),
                        _buildTag(field.dimensions ?? 'N/A', AppTheme.accentColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Close Button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppTheme.primaryText),
                onPressed: onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Text(
        text,
        style: AppTheme.bodyMedium.copyWith(color: color),
      ),
    );
  }
}
