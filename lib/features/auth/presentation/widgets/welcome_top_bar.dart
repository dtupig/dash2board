import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Barra superior da `WelcomeScreen` - só o alternador de tema. Isolado
/// para manter aquele arquivo abaixo do limite de 250 linhas.
class WelcomeTopBar extends StatelessWidget {
  const WelcomeTopBar({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Tooltip(
            message: isDark ? 'Usar tema claro' : 'Usar tema escuro',
            child: IconButton(
              onPressed: onToggleTheme,
              iconSize: 20,
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(
                  scheme.surfaceContainer.withValues(alpha: 0.6),
                ),
                shape: const WidgetStatePropertyAll<OutlinedBorder>(
                  CircleBorder(),
                ),
                minimumSize: const WidgetStatePropertyAll<Size>(Size(44, 44)),
              ),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
