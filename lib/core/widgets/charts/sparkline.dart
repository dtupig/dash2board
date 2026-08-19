import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/chart_tokens.dart';
import 'chart_motion.dart';

/// Traço de tendência de série única: sem eixos, sem grade, sem rótulos.
///
/// Usado dentro de [KpiTile] ou em qualquer lugar onde o contexto ao redor já
/// diz o que a série representa - o `Sparkline` só mostra a forma da
/// tendência.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.color,
    this.semanticLabel,
  });

  /// Valores da série, em ordem cronológica.
  final List<double> values;

  /// Cor do traço. Por padrão usa o primeiro slot categórico ("nossa
  /// organização"), a entidade mais comum para uma sparkline solitária.
  final Color? color;

  final String? semanticLabel;

  String _describe() {
    if (values.isEmpty) {
      return 'Sem dados de tendência.';
    }
    final double min = values.reduce(math.min);
    final double max = values.reduce(math.max);
    return 'Tendência de ${values.length} pontos, entre '
        '${min.toStringAsFixed(0)} e ${max.toStringAsFixed(0)}, valor mais '
        'recente ${values.last.toStringAsFixed(0)}.';
  }

  @override
  Widget build(BuildContext context) {
    final Color lineColor = color ?? ChartTokens.categoricalSlot1;

    return Semantics(
      label: semanticLabel ?? _describe(),
      container: true,
      excludeSemantics: true,
      child: ChartReveal(
        child: CustomPaint(
          size: Size.infinite,
          painter: _SparklinePainter(values: values, color: lineColor),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final double minValue = values.reduce(math.min);
    final double maxValue = values.reduce(math.max);
    final double range =
        (maxValue - minValue).abs() < 1e-9 ? 1 : maxValue - minValue;

    final double stepX = size.width / (values.length - 1);
    final Paint linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = ChartTokens.lineStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    for (int i = 0; i < values.length; i++) {
      final double x = stepX * i;
      final double normalized = (values[i] - minValue) / range;
      final double y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
