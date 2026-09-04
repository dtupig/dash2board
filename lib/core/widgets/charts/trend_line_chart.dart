import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/chart_tokens.dart';
import 'chart_legend.dart';
import 'chart_motion.dart';
import 'trend_line_chart_painter.dart';
import 'trend_line_chart_tooltip.dart';
import 'trend_series.dart';

export 'trend_series.dart' show TrendSeries;

/// Gráfico de linha de tendência: até 3 séries, um único eixo Y, grade
/// horizontal recessiva, legenda a partir de 2 séries e rótulo direto apenas
/// no último ponto de cada série. Toque em um ponto abre um tooltip com data
/// e valores de todas as séries naquele X (crosshair).
///
/// O limite de 3 séries é uma regra dura, não uma sugestão: passar uma 4ª
/// série lança [AssertionError] em vez de ciclar cores (regra 2). O tooltip
/// e o `CustomPainter` vivem em `trend_line_chart_tooltip.dart` e
/// `trend_line_chart_painter.dart`, para manter este arquivo abaixo do
/// limite de 250 linhas.
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
    final String seriesDescriptions = widget.series.map((TrendSeries s) {
      final double first = s.values.first;
      final double last = s.values.last;
      return '${s.label} de ${first.toStringAsFixed(0)} para '
          '${last.toStringAsFixed(0)}${widget.valueSuffix}';
    }).join('; ');
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
                              painter: TrendPainter(
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
                            TrendTooltip(
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
