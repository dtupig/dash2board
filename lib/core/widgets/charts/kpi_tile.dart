import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../surface_card.dart';
import 'delta_badge.dart';
import 'sparkline.dart';

/// "Um número que importa": rótulo, valor grande, unidade opcional, selo de
/// variação opcional e sparkline opcional.
///
/// É a forma correta quando um número basta - não force um [TrendLineChart]
/// ou um [DomainBarChart] onde este cartão já responde a pergunta do
/// executivo.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.delta,
    this.sparklineValues,
    this.accent,
  });

  /// Rótulo curto do indicador (ex.: "Índice de postura").
  final String label;

  /// Valor já formatado para exibição (ex.: "72").
  final String value;

  /// Unidade opcional (ex.: "pontos", "%").
  final String? unit;

  /// Selo de variação opcional, já pronto (ver [DeltaBadge]).
  final DeltaBadge? delta;

  /// Série opcional para a sparkline de contexto.
  final List<double>? sparklineValues;

  /// Cor de acento do cartão (persona/severidade). Opcional.
  final Color? accent;

  String _semanticLabel() {
    final String unitSuffix = unit == null ? '' : ' $unit';
    return '$label: $value$unitSuffix.';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final List<double>? spark = sparklineValues;

    return Semantics(
      // O rótulo composto cobre label+valor+unidade; `delta` e a sparkline
      // já têm sua própria `Semantics` (com a frase "subiu/caiu" e a
      // descrição da tendência) e por isso ficam FORA do `ExcludeSemantics`
      // abaixo - excluir a árvore inteira apagaria essa informação, que não
      // está duplicada em `_semanticLabel()`.
      label: _semanticLabel(),
      container: true,
      child: SurfaceCard(
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        value,
                        style: textTheme.displaySmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      if (unit != null) ...<Widget>[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          unit!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (delta != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              delta!,
            ],
            if (spark != null && spark.length >= 2) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(height: 32, child: Sparkline(values: spark)),
            ],
          ],
        ),
      ),
    );
  }
}
