import 'package:flutter/material.dart';
import '../../domain/models/map_field.dart';
import '../../../auth/presentation/theme/app_theme.dart';

class FieldDetailsCard extends StatelessWidget {
  final MapField field;
  final VoidCallback? onClose;

  const FieldDetailsCard({
    Key? key,
    required this.field,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Field image
          Container(
            width: 100,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              image: field.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(field.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: field.photoUrl == null
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2D5A3D), Color(0xFF1A3A26)],
                    )
                  : null,
            ),
            child: field.photoUrl == null
                ? const Center(
                    child: Icon(
                      Icons.sports_soccer,
                      size: 32,
                      color: Colors.white70,
                    ),
                  )
                : null,
          ),
          
          // Field details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Field name
                  Text(
                    field.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Address - mock for now
                  const Text(
                    'Rua do Campo, 123',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating
                  Row(
                    children: [
                      ...List.generate(5, (index) => Icon(
                        index < 4 ? Icons.star : (index == 4 ? Icons.star_half : Icons.star_border),
                        color: const Color(0xFFFFD700),
                        size: 14,
                      )),
                      const SizedBox(width: 4),
                      const Text(
                        '4.5',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Tags
                  Row(
                    children: [
                      _buildTag('Natural', const Color(0xFF2D5A3D)),
                      const SizedBox(width: 8),
                      _buildTag(field.dimensions ?? '40x70m', const Color(0xFF1A3A26)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Close button
          if (onClose != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
