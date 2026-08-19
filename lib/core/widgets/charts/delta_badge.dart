import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/chart_tokens.dart';

/// Selo de variação (delta) com seta e sinal, na escala divergente.
///
/// Zero usa o cinza neutro - não é "positivo fraco" nem "negativo fraco", é a
/// ausência de variação. A cor fica só no ícone e no fundo: o número em si
/// usa um token de texto do tema (regra 6 de `chart_tokens.dart`).
class DeltaBadge extends StatelessWidget {
  const DeltaBadge({
    super.key,
    required this.value,
    this.unitLabel = 'pontos',
    this.periodLabel,
    this.invertPolarity = false,
    this.magnitudeFormatter,
  });

  /// Variação já calculada (ex.: `overallScore - previousScore`).
  final num value;

  /// Unidade do valor (ex.: "pontos", "%").
  final String unitLabel;

  /// Período de referência, exibido junto ao valor (ex.: "em 30 dias").
  final String? periodLabel;

  /// Inverte qual sinal é "bom" (teal) e qual é "ruim" (âmbar).
  ///
  /// Por padrão, subir é bom (índice de postura, cobertura de controle). Em
  /// métricas onde subir é ruim - exposição financeira, número de lacunas -
  /// use `true`: a seta continua mostrando a direção real do número (isso é
  /// fato, não muda), só a cor de sentimento inverte.
  final bool invertPolarity;

  /// Formata a magnitude (já sem sinal) para exibição. `null` mantém o
  /// padrão (`toStringAsFixed`) - use para moeda (ex.: "1,4 mi" em vez de
  /// "1400000.0").
  final String Function(num magnitude)? magnitudeFormatter;

  bool get _isPositive => value > 0;

  bool get _isNegative => value < 0;

  Color _colorFor() {
    final bool goodDirectionIsUp = !invertPolarity;
    if (_isPositive) {
      return goodDirectionIsUp
          ? ChartTokens.divergentPositive
          : ChartTokens.divergentNegative;
    }
    if (_isNegative) {
      return goodDirectionIsUp
          ? ChartTokens.divergentNegative
          : ChartTokens.divergentPositive;
    }
    return ChartTokens.divergentNeutral;
  }

  IconData _iconFor() {
    if (_isPositive) {
      return Icons.arrow_upward_rounded;
    }
    if (_isNegative) {
      return Icons.arrow_downward_rounded;
    }
    return Icons.remove_rounded;
  }

  String _magnitudeText() {
    final num magnitude = value.abs();
    if (magnitudeFormatter != null) {
      return magnitudeFormatter!(magnitude);
    }
    final bool isWhole = magnitude % 1 == 0;
    return isWhole
        ? magnitude.toStringAsFixed(0)
        : magnitude.toStringAsFixed(1);
  }

  String _valueText() {
    final String sign = _isPositive ? '+' : (_isNegative ? '−' : '');
    final String unitSuffix = unitLabel.isEmpty ? '' : ' $unitLabel';
    return '$sign${_magnitudeText()}$unitSuffix';
  }

  String _semanticSentence() {
    final String suffix = periodLabel == null ? '' : ' $periodLabel';
    if (_isPositive) {
      return 'Subiu ${_magnitudeText()} $unitLabel$suffix.';
    }
    if (_isNegative) {
      return 'Caiu ${_magnitudeText()} $unitLabel$suffix.';
    }
    return 'Estável$suffix.';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color color = _colorFor();

    return Semantics(
      label: _semanticSentence(),
      container: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.buttonRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(_iconFor(), size: 14, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _valueText(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              if (periodLabel != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  periodLabel!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
