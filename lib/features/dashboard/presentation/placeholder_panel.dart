import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/surface_card.dart';

/// Cartão de "próxima entrega", usado hoje só no painel de Operação.
///
/// Estratégia e Board já têm telas reais; Operação ainda não - este cartão
/// existe para que o roteamento por persona seja verificável ponta a ponta
/// sem fingir que o dado já está sendo lido. O rótulo "Em breve" é
/// deliberado: nenhum caminho interno (coleção do Firestore, nome de
/// variável) aparece para quem está usando o produto.
class PlaceholderPanel extends StatelessWidget {
  const PlaceholderPanel({
    super.key,
    required this.title,
    required this.description,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String description;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SurfaceCard(
        accent: accent,
        semanticLabel: '$title. $description. Ainda em construção.',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 20, color: accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Em breve',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(description, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
