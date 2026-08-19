import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/chart_tokens.dart';
import 'chart_legend.dart';
import 'chart_motion.dart';

/// Barra 100% empilhada para compliance: `compliant` / `partial` / `gap`.
///
/// As três cores são de ESTADO, não de série (regra 1 de
/// `chart_tokens.dart`): reusam os semânticos já declarados em `AppColors`
/// (`success`/`warning`/`danger`), nunca um novo hexadecimal. A legenda usa
/// ícone + rótulo, nunca só cor (regra 5).
class StackedStatusBar extends StatelessWidget {
  const StackedStatusBar({
    super.key,
    required this.compliantCount,
    required this.partialCount,
    required this.gapCount,
    this.height = 28,
  });

  final int compliantCount;
  final int partialCount;
  final int gapCount;
  final double height;

  int get _total => compliantCount + partialCount + gapCount;

  String _percentOf(int count) {
    if (_total == 0) {
      return '0%';
    }
    return '${((count / _total) * 100).round()}%';
  }

  String _semanticLabel() {
    if (_total == 0) {
      return 'Sem controles de compliance para exibir.';
    }
    return 'Compliance de $_total controles: ${_percentOf(compliantCount)} '
        'conforme, ${_percentOf(partialCount)} parcial, '
        '${_percentOf(gapCount)} em lacuna.';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final List<_StackSegment> segments = <_StackSegment>[
      if (compliantCount > 0)
        _StackSegment(count: compliantCount, color: AppColors.success),
      if (partialCount > 0)
        _StackSegment(count: partialCount, color: AppColors.warning),
      if (gapCount > 0) _StackSegment(count: gapCount, color: AppColors.danger),
    ];

    return Semantics(
      label: _semanticLabel(),
      container: true,
      excludeSemantics: true,
      child: ChartReveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: height,
              child: _total == 0
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant.withValues(
                          alpha: ChartTokens.gridMaxAlpha,
                        ),
                        borderRadius: BorderRadius.circular(
                          ChartTokens.barEndRadius,
                        ),
                      ),
                    )
                  : Row(
                      children: <Widget>[
                        for (int i = 0; i < segments.length; i++) ...<Widget>[
                          if (i > 0)
                            const SizedBox(
                                width: ChartTokens.stackedSegmentGap),
                          Expanded(
                            flex: segments[i].count,
                            child: Container(
                              decoration: BoxDecoration(
                                color: segments[i].color,
                                borderRadius: BorderRadius.horizontal(
                                  left: i == 0
                                      ? const Radius.circular(
                                          ChartTokens.barEndRadius,
                                        )
                                      : Radius.zero,
                                  right: i == segments.length - 1
                                      ? const Radius.circular(
                                          ChartTokens.barEndRadius,
                                        )
                                      : Radius.zero,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ChartLegend(
              entries: <ChartLegendEntry>[
                ChartLegendEntry(
                  label: 'Conforme (${_percentOf(compliantCount)})',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
                ChartLegendEntry(
                  label: 'Parcial (${_percentOf(partialCount)})',
                  icon: Icons.remove_circle_outline_rounded,
                  color: AppColors.warning,
                ),
                ChartLegendEntry(
                  label: 'Lacuna (${_percentOf(gapCount)})',
                  icon: Icons.highlight_off_rounded,
                  color: AppColors.danger,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StackSegment {
  const _StackSegment({required this.count, required this.color});

  final int count;
  final Color color;
}
