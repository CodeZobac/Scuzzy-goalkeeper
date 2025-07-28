import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../features/auth/presentation/theme/app_theme.dart';

/// Widget that displays a demo mode indicator when the app is running
/// without proper environment configuration
class DemoModeIndicator extends StatelessWidget {
  const DemoModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show if in demo mode
    if (!AppConfig.isDemoMode) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFF9800), // Orange color for demo notice
      child: SafeArea(
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Modo Demo - Dados simulados para demonstração',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showDemoModeInfo(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDemoModeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFFFF9800),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Modo Demo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta aplicação está a funcionar em modo demo devido à configuração em falta:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
            SizedBox(height: 16),
            _DemoModePoint(
              icon: Icons.storage,
              text: 'Base de dados (Supabase) não configurada',
            ),
            _DemoModePoint(
              icon: Icons.map,
              text: 'Token do Mapbox em falta ou inválido',
            ),
            _DemoModePoint(
              icon: Icons.preview,
              text: 'A usar dados simulados para demonstração',
            ),
            _DemoModePoint(
              icon: Icons.lock_outline,
              text: 'Funcionalidades de autenticação desativadas',
            ),
            SizedBox(height: 16),
            Text(
              'Para configurar a aplicação corretamente, defina as variáveis de ambiente necessárias.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Entendi',
              style: TextStyle(
                color: Color(0xFFFF9800),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoModePoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DemoModePoint({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C2C2C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
