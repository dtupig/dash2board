import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/chart_tokens.dart';
import 'chart_legend.dart';
import 'chart_motion.dart';

const List<String> _monthAbbreviations = <String>[
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

String _formatMonth(DateTime date) {
  final String year2 = (date.year % 100).toString().padLeft(2, '0');
  return '${_monthAbbreviations[date.month - 1]}/$year2';
}

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

/// Gráfico de linha de tendência: até 3 séries, um único eixo Y, grade
/// horizontal recessiva, legenda a partir de 2 séries e rótulo direto apenas
/// no último ponto de cada série. Toque em um ponto abre um tooltip com data
/// e valores de todas as séries naquele X (crosshair).
///
/// O limite de 3 séries é uma regra dura, não uma sugestão: passar uma 4ª
/// série lança [AssertionError] em vez de ciclar cores (regra 2).
class TrendLineChart extends StatefulWidget {
  TrendLineChart({
    super.key,
    required this.timestamps,
    required this.series,
    this.valueSuffix = '',
    this.yAxisMin,
    this.yAxisMax,
    this.gridLineCount = 3,
  })  : assert(
          series.isNotEmpty,
          'TrendLineChart precisa de ao menos 1 série.',
        ),
        assert(
          series.length <= 3,
          'TrendLineChart aceita no máximo 3 séries - uma 4ª série vira '
          '"Outros" ou um gráfico separado, nunca um ciclo de cor.',
        ),
        assert(
          series.every(
            (TrendSeries s) => s.values.length == timestamps.length,
          ),
          'Cada série precisa ter exatamente um valor por marca de tempo.',
        ),
        assert(
          (yAxisMin == null) == (yAxisMax == null),
          'yAxisMin e yAxisMax devem ser fornecidos juntos, ou nenhum dos '
          'dois (nesse caso a escala é calculada a partir dos dados).',
        ),
        assert(
          yAxisMin == null || yAxisMax! > yAxisMin,
          'yAxisMax precisa ser maior que yAxisMin.',
        );

  final List<DateTime> timestamps;
  final List<TrendSeries> series;
  final String valueSuffix;

  /// Piso fixo do eixo Y. `null` (padrão) calcula a escala a partir do menor
  /// valor das séries - use um piso fixo para métricas com faixa conhecida
  /// (ex.: índice de postura, sempre 0-100), onde uma escala automática
  /// exageraria visualmente pequenas variações.
  final double? yAxisMin;

  /// Teto fixo do eixo Y. Ver [yAxisMin].
  final double? yAxisMax;

  /// Quantidade de DIVISÕES da grade horizontal (o número de linhas
  /// desenhadas é `gridLineCount + 1`). Com [yAxisMin]/[yAxisMax] fixos em
  /// 0/100, use 4 para uma grade a cada 25 pontos.
  final int gridLineCount;

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int? _hoverIndex;

  void _updateHover(Offset localPosition, Size size) {
    if (widget.timestamps.length < 2 || size.width <= 0) {
      return;
    }
    final double stepX = size.width / (widget.timestamps.length - 1);
    final int index = (localPosition.dx / stepX)
        .round()
        .clamp(0, widget.timestamps.length - 1)
        .toInt();
    if (index != _hoverIndex) {
      setState(() => _hoverIndex = index);
    }
  }

  void _clearHover() {
    if (_hoverIndex != null) {
      setState(() => _hoverIndex = null);
    }
  }

  String _semanticLabel() {
    final int count = widget.series.length;
    final String seriesDescriptions = widget.series
        .map((TrendSeries s) {
          final double first = s.values.first;
          final double last = s.values.last;
          return '${s.label} de ${first.toStringAsFixed(0)} para '
              '${last.toStringAsFixed(0)}${widget.valueSuffix}';
        })
        .join('; ');
    return 'Gráfico de tendência com $count série${count > 1 ? 's' : ''}: '
        '$seriesDescriptions.';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Semantics(
      label: _semanticLabel(),
      container: true,
      child: ChartReveal(
        child: Column(
          children: <Widget>[
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Size size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return ExcludeSemantics(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (TapDownDetails details) =>
                          _updateHover(details.localPosition, size),
                      onPanStart: (DragStartDetails details) =>
                          _updateHover(details.localPosition, size),
                      onPanUpdate: (DragUpdateDetails details) =>
                          _updateHover(details.localPosition, size),
                      onPanEnd: (_) => _clearHover(),
                      onTapCancel: _clearHover,
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _TrendPainter(
                                timestamps: widget.timestamps,
                                series: widget.series,
                                gridColor: scheme.outlineVariant,
                                textColor: scheme.onSurface,
                                mutedTextColor: scheme.onSurfaceVariant,
                                crosshairColor: ChartTokens.divergentNeutral,
                                hoverIndex: _hoverIndex,
                                valueSuffix: widget.valueSuffix,
                                yAxisMin: widget.yAxisMin,
                                yAxisMax: widget.yAxisMax,
                                gridLineCount: widget.gridLineCount,
                              ),
                            ),
                          ),
                          if (_hoverIndex != null)
                            _Tooltip(
                              timestamps: widget.timestamps,
                              series: widget.series,
                              index: _hoverIndex!,
                              size: size,
                              valueSuffix: widget.valueSuffix,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.series.length >= 2) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              ChartLegend(
                entries: widget.series
                    .map(
                      (TrendSeries s) =>
                          ChartLegendEntry(label: s.label, color: s.color),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({
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
    final double left =
        (x - tooltipWidth / 2).clamp(0, math.max(0, size.width - tooltipWidth)).toDouble();

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
                _formatMonth(timestamps[index]),
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

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
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
    final double range = (maxValue - minValue).abs() < 1e-9
        ? 1
        : maxValue - minValue;

    _drawGrid(canvas, plotArea);

    final double stepX = timestamps.length > 1
        ? plotArea.width / (timestamps.length - 1)
        : 0;

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
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    painter.layout(maxWidth: math.max(0, plotArea.width - x - 4));
    final double dx = (x + 6).clamp(0, math.max(0, plotArea.width - painter.width)).toDouble();
    final double dy = (y - painter.height / 2).clamp(plotArea.top, plotArea.bottom).toDouble();
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
        Offset(dx.clamp(0, size.width - painter.width).toDouble(), size.height - painter.height),
      );
    }

    paintLabel(_formatMonth(timestamps.first), 0, alignEnd: false);
    if (timestamps.length > 1) {
      paintLabel(
        _formatMonth(timestamps.last),
        plotArea.width,
        alignEnd: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
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
