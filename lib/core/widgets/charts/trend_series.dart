import 'package:flutter/material.dart';

/// Uma série de [TrendLineChart].
///
/// A cor é responsabilidade de quem chama - normalmente um dos três slots
/// fixos de `ChartTokens.categorical`, sempre o mesmo para a mesma entidade.
/// Assim, filtrar uma série nunca repinta as que sobraram (regra 4 de
/// `chart_tokens.dart`): a cor viaja com a entidade, não com a posição na
/// lista passada ao widget.
class TrendSeries {
  const TrendSeries({
    required this.label,
    required this.values,
    required this.color,
  });

  final String label;
  final List<double> values;
  final Color color;
}
