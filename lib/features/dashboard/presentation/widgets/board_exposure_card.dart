import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/charts/delta_badge.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../strategic/presentation/briefing_formatting.dart';

/// Bloco 1 do painel do board: exposição financeira estimada (hero number)
/// - a "perda esperada por ano se nada mudar", em Real e como percentual da
/// receita. Extraído de `board_dashboard_screen.dart` (Bucket B,
/// `docs/21_BACKLOG_ACHADOS_TECNICOS.md`) ao dar a HU-W-14 seu layout de
/// tela larga - mesmo conteúdo de antes, só isolado para reaproveitar nas
/// duas composições (empilhada e lado a lado).
class BoardExposureCard extends StatelessWidget {
  const BoardExposureCard({
    super.key,
    required this.totalAle,
    required this.percentOfRevenue,
    required this.quarterlyDelta,
  });

  final double totalAle;
  final double percentOfRevenue;
  final double quarterlyDelta;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SurfaceCard(
      semanticLabel:
          'Exposição financeira estimada: ${formatCurrencyBrl(totalAle)}, '
          '${percentOfRevenue.toStringAsFixed(1)} por cento da receita '
          'anual.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Exposição financeira estimada',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  formatCurrencyBrl(totalAle),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${percentOfRevenue.toStringAsFixed(1)}% da receita anual',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DeltaBadge(
            value: quarterlyDelta,
            unitLabel: '',
            periodLabel: 'no trimestre',
            invertPolarity: true,
            magnitudeFormatter: formatCurrencyCompactBrl,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Este número é a perda que a empresa esperaria sofrer por ano '
            'se nada mudar nos riscos abertos hoje, somando a chance de '
            'cada um acontecer com o quanto custaria. Vem dos riscos '
            'cadastrados pela área de segurança.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
