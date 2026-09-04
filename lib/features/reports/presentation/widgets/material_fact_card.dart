import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../domain/material_fact.dart';
import '../reports_formatting.dart';

/// Um fato relevante, em linguagem de negócio - é o que a persona `board`
/// lê. Nunca mostra o nome técnico do gatilho, CVE, CVSS ou nome de
/// ferramenta.
class MaterialFactCard extends StatelessWidget {
  const MaterialFactCard({super.key, required this.fact});

  final MaterialFact fact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return SurfaceCard(
      accent: scheme.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.priority_high_rounded, color: scheme.error, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  fact.title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(fact.consequence, style: theme.textTheme.bodyMedium),
          if (fact.estimatedExposure != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Exposição estimada: '
              '${formatReportCurrencyBrl(fact.estimatedExposure!)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          if (fact.decisionRequired) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Decisão do board necessária.',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.error, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
