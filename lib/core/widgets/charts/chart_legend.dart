import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Uma entrada de legenda: marcador (cor ou ícone) + rótulo.
///
/// Nunca é só cor (regra 5 de `chart_tokens.dart`): por isso [label] é
/// obrigatório mesmo quando [color] já identifica a série.
class ChartLegendEntry {
  const ChartLegendEntry({required this.label, this.color, this.icon})
      : assert(
          color != null || icon != null,
          'ChartLegendEntry precisa de color ou icon para desenhar o marcador.',
        );

  final String label;

  /// Marcador circular desta cor. Usado quando a entrada representa uma
  /// série categórica.
  final Color? color;

  /// Marcador em forma de ícone. Usado quando a entrada representa um
  /// estado (ex.: compliance), onde a legenda precisa de ícone + rótulo.
  final IconData? icon;
}

/// Legenda genérica de gráfico: marcador + rótulo, quebrando em linhas
/// quando não couber na largura disponível.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.entries});

  final List<ChartLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      container: true,
      label:
          'Legenda: ${entries.map((ChartLegendEntry e) => e.label).join(', ')}.',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final ChartLegendEntry entry in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (entry.icon != null)
                  Icon(
                    entry.icon,
                    size: 14,
                    color: entry.color ?? scheme.onSurfaceVariant,
                  )
                else
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  entry.label,
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
