import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/chart_tokens.dart';
import 'domain_bar_chart.dart';

/// Uma linha (barra + rótulo + valor) de `DomainBarChart` - isolada para
/// manter aquele arquivo abaixo do limite de 250 linhas.
class DomainBarRow extends StatelessWidget {
  const DomainBarRow({
    super.key,
    required this.datum,
    required this.maxValue,
    required this.peerMedian,
    required this.valueLabel,
    required this.valueColumnWidth,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final DomainBarDatum datum;
  final double maxValue;
  final double? peerMedian;
  final String valueLabel;
  final double valueColumnWidth;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    final Widget row = Row(
      children: <Widget>[
        SizedBox(
          width: 104,
          child: Text(
            datum.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double trackWidth = constraints.maxWidth;
              final double fraction = maxValue <= 0
                  ? 0
                  : (datum.value / maxValue).clamp(0, 1).toDouble();
              final double fillWidth = trackWidth * fraction;
              final double? medianX = peerMedian == null || maxValue <= 0
                  ? null
                  : trackWidth * (peerMedian! / maxValue).clamp(0, 1);

              return SizedBox(
                height: 14,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant.withValues(
                          alpha: ChartTokens.gridMaxAlpha,
                        ),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(ChartTokens.barEndRadius),
                        ),
                      ),
                      child: const SizedBox(height: 14, width: double.infinity),
                    ),
                    Container(
                      width: fillWidth,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(ChartTokens.barEndRadius),
                        ),
                      ),
                    ),
                    if (medianX != null)
                      Positioned(
                        left: (medianX - 1).clamp(0, trackWidth - 2).toDouble(),
                        child: Container(
                          width: 2,
                          height: 18,
                          color: ChartTokens.categoricalSlot2,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: valueColumnWidth,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
          ),
        ),
      ],
    );

    if (onTap == null) {
      return row;
    }

    final String semanticLabel =
        '${datum.label}: $valueLabel${selected ? ', selecionado' : ''}.';

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : const Color(0x00000000),
        borderRadius: AppRadius.fieldRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.fieldRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Center(child: row),
            ),
          ),
        ),
      ),
    );
  }
}
