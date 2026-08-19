import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Cartão base do Dash2Board.
///
/// Não usamos `Card`/`CardTheme` de propósito: nas versões recentes do Flutter
/// `ThemeData.cardTheme` passou a exigir `CardThemeData`, e queremos um
/// componente estável e livre de deprecations, com controle total de borda,
/// preenchimento e brilho de acento.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.accent,
    this.onTap,
    this.selected = false,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Cor de acento da persona/severidade. Quando nula usa o outline do tema.
  final Color? accent;

  final VoidCallback? onTap;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accentColor = accent ?? scheme.primary;

    final Widget content = AnimatedContainer(
      duration: AppDuration.fast,
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.surfaceContainer,
            selected
                ? accentColor.withValues(alpha: 0.10)
                : scheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(
          color: selected
              ? accentColor.withValues(alpha: 0.70)
              : scheme.outline.withValues(alpha: 0.60),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: selected
                ? accentColor.withValues(alpha: 0.18)
                : scheme.shadow.withValues(alpha: 0.28),
            blurRadius: selected ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return Semantics(label: semanticLabel, container: true, child: content);
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      container: true,
      child: Material(
        color: const Color(0x00000000),
        borderRadius: AppRadius.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          splashColor: accentColor.withValues(alpha: 0.10),
          highlightColor: accentColor.withValues(alpha: 0.06),
          child: content,
        ),
      ),
    );
  }
}
