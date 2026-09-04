import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/chart_tokens.dart';
import 'trend_line_chart_format.dart';
import 'trend_series.dart';

/// `CustomPainter` do `TrendLineChart` - desenha grade, linhas, rótulo
/// direto no último ponto e crosshair. Isolado para manter
/// `trend_line_chart.dart` abaixo do limite de 250 linhas.
class TrendPainter extends CustomPainter {
  const TrendPainter({
    required this.timestamps,
    required this.series,
    required this.gridColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.crosshairColor,
    required this.hoverIndex,
    required this.valueSuffix,
    required this.yAxisMin,
    required this.yAxisMax,
    required this.gridLineCount,
  });

  final List<DateTime> timestamps;
  final List<TrendSeries> series;
  final Color gridColor;
  final Color textColor;
  final Color mutedTextColor;
  final Color crosshairColor;
  final int? hoverIndex;
  final String valueSuffix;
  final double? yAxisMin;
  final double? yAxisMax;
  final int gridLineCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (timestamps.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    // Reservamos uma faixa inferior para os rótulos de mês do eixo X.
    const double bottomAxisHeight = 18;
    final double plotHeight = math.max(0, size.height - bottomAxisHeight);
    final Rect plotArea = Rect.fromLTWH(0, 0, size.width, plotHeight);

    final double minValue;
    final double maxValue;
    if (yAxisMin != null && yAxisMax != null) {
      minValue = yAxisMin!;
      maxValue = yAxisMax!;
    } else {
      final List<double> allValues = <double>[
        for (final TrendSeries s in series) ...s.values,
      ];
      minValue = allValues.reduce(math.min);
      maxValue = allValues.reduce(math.max);
    }
    final double range =
        (maxValue - minValue).abs() < 1e-9 ? 1 : maxValue - minValue;

    _drawGrid(canvas, plotArea);

    final double stepX =
        timestamps.length > 1 ? plotArea.width / (timestamps.length - 1) : 0;

    double yFor(double value) {
      final double normalized = (value - minValue) / range;
      return plotArea.bottom - normalized * plotArea.height;
    }

    for (int si = 0; si < series.length; si++) {
      final TrendSeries s = series[si];
      final Path path = Path();
      for (int i = 0; i < s.values.length; i++) {
        final double x = stepX * i;
        final double y = yFor(s.values[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      if (si == 0) {
        final Path areaPath = Path.from(path)
          ..lineTo(stepX * (s.values.length - 1), plotArea.bottom)
          ..lineTo(0, plotArea.bottom)
          ..close();
        final Paint areaPaint = Paint()
          ..color = s.color.withValues(alpha: ChartTokens.areaFillAlpha)
          ..style = PaintingStyle.fill;
        canvas.drawPath(areaPath, areaPaint);
      }

      final Paint linePaint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ChartTokens.lineStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);

      // Rótulo direto: só no último ponto (regra 9 - seletivo, nunca um
      // número em cada ponto).
      final double lastX = stepX * (s.values.length - 1);
      final double lastY = yFor(s.values.last);
      canvas.drawCircle(
        Offset(lastX, lastY),
        ChartTokens.pointMinDiameter / 2,
        Paint()..color = s.color,
      );
      _drawDirectLabel(canvas, plotArea, s, lastX, lastY);
    }

    if (hoverIndex != null && hoverIndex! < timestamps.length) {
      _drawCrosshair(canvas, plotArea, stepX, hoverIndex!, yFor);
    }

    _drawAxisLabels(canvas, size, plotArea, stepX);
  }

  void _drawGrid(Canvas canvas, Rect plotArea) {
    final Paint gridPaint = Paint()
      ..color = gridColor.withValues(alpha: ChartTokens.gridMaxAlpha)
      ..strokeWidth = 1;
    for (int i = 0; i <= gridLineCount; i++) {
      final double y = plotArea.top + (plotArea.height / gridLineCount) * i;
      canvas.drawLine(
        Offset(plotArea.left, y),
        Offset(plotArea.right, y),
        gridPaint,
      );
    }
  }

  void _drawDirectLabel(
    Canvas canvas,
    Rect plotArea,
    TrendSeries s,
    double x,
    double y,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: '${s.label} ${s.values.last.toStringAsFixed(0)}$valueSuffix',
        style: TextStyle(
            color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    painter.layout(maxWidth: math.max(0, plotArea.width - x - 4));
    final double dx = (x + 6)
        .clamp(0, math.max(0, plotArea.width - painter.width))
        .toDouble();
    final double dy = (y - painter.height / 2)
        .clamp(plotArea.top, plotArea.bottom)
        .toDouble();
    painter.paint(canvas, Offset(dx, dy));
  }

  void _drawCrosshair(
    Canvas canvas,
    Rect plotArea,
    double stepX,
    int index,
    double Function(double) yFor,
  ) {
    final double x = stepX * index;
    final Paint crosshairPaint = Paint()
      ..color = crosshairColor.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(x, plotArea.top),
      Offset(x, plotArea.bottom),
      crosshairPaint,
    );
    for (final TrendSeries s in series) {
      final double y = yFor(s.values[index]);
      canvas.drawCircle(
        Offset(x, y),
        ChartTokens.pointMinDiameter / 2,
        Paint()..color = s.color,
      );
      canvas.drawCircle(
        Offset(x, y),
        ChartTokens.pointMinDiameter / 2,
        Paint()
          ..color = mutedTextColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size, Rect plotArea, double stepX) {
    if (timestamps.isEmpty) {
      return;
    }
    void paintLabel(String text, double x, {required bool alignEnd}) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: mutedTextColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final double dx = alignEnd ? x - painter.width : x;
      painter.paint(
        canvas,
        Offset(dx.clamp(0, size.width - painter.width).toDouble(),
            size.height - painter.height),
      );
    }

    paintLabel(formatMonth(timestamps.first), 0, alignEnd: false);
    if (timestamps.length > 1) {
      paintLabel(
        formatMonth(timestamps.last),
        plotArea.width,
        alignEnd: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) {
    // As cores vêm do tema (`Theme.of(context).colorScheme`): sem compará-
    // las aqui, alternar claro/escuro não repintaria o traço enquanto
    // série, datas e hover não mudassem juntos.
    return oldDelegate.series != series ||
        oldDelegate.timestamps != timestamps ||
        oldDelegate.hoverIndex != hoverIndex ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedTextColor != mutedTextColor ||
        oldDelegate.crosshairColor != crosshairColor ||
        oldDelegate.valueSuffix != valueSuffix ||
        oldDelegate.yAxisMin != yAxisMin ||
        oldDelegate.yAxisMax != yAxisMax ||
        oldDelegate.gridLineCount != gridLineCount;
  }
}
