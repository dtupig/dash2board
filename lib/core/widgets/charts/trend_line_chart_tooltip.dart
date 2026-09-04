import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'trend_line_chart_format.dart';
import 'trend_series.dart';

/// Tooltip de crosshair do `TrendLineChart` - aparece no ponto tocado, com
/// data e valor de todas as séries naquele X. Isolado para manter
/// `trend_line_chart.dart` abaixo do limite de 250 linhas.
class TrendTooltip extends StatelessWidget {
  const TrendTooltip({
    super.key,
    required this.timestamps,
    required this.series,
    required this.index,
    required this.size,
    required this.valueSuffix,
  });

  final List<DateTime> timestamps;
  final List<TrendSeries> series;
  final int index;
  final Size size;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    const double tooltipWidth = 168;
    final double stepX =
        timestamps.length > 1 ? size.width / (timestamps.length - 1) : 0;
    final double x = stepX * index;
    final double left = (x - tooltipWidth / 2)
        .clamp(0, math.max(0, size.width - tooltipWidth))
        .toDouble();

    return Positioned(
      left: left,
      top: 0,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: AppRadius.fieldRadius,
            border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                formatMonth(timestamps[index]),
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              for (final TrendSeries s in series)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        '${s.values[index].toStringAsFixed(0)}$valueSuffix',
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
