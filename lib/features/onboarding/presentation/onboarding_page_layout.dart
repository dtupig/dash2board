import 'package:flutter/material.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import 'onboarding_content.dart';

/// Corpo de uma tela da introdução: selo com ícone, título e descrição.
///
/// Em [LayoutSize.large] (monitor/navegador maximizado), o selo fica ao lado
/// do texto em vez de em cima - "passo e ilustração lado a lado" (HU-W-08).
/// Nas demais faixas, mantém a coluna centralizada que já existia antes da
/// web (nenhuma mudança visual no app mobile).
class OnboardingPageLayout extends StatelessWidget {
  const OnboardingPageLayout({
    super.key,
    required this.page,
    required this.accent,
  });

  final OnboardingPageData page;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bool isLarge = LayoutSize.of(context) == LayoutSize.large;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Widget badge =
        _Badge(icon: page.icon, accent: accent, large: isLarge);
    final Widget text = Column(
      crossAxisAlignment:
          isLarge ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            page.title,
            textAlign: isLarge ? TextAlign.left : TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          page.description,
          textAlign: isLarge ? TextAlign.left : TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    if (!isLarge) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                badge,
                const SizedBox(height: AppSpacing.xl),
                text,
              ],
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints:
          const BoxConstraints(maxWidth: 2 * AppSpacing.maxContentWidth),
      child: Center(
        child: SingleChildScrollView(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              badge,
              const SizedBox(width: AppSpacing.xxl),
              Flexible(child: text),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.accent, required this.large});

  final IconData icon;
  final Color accent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final double size = large ? 120 : 88;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: large ? 52 : 40, color: accent),
    );
  }
}
