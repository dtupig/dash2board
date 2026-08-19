import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/chart_tokens.dart';
import 'chart_motion.dart';

/// Um item de [DomainBarChart]: rótulo do eixo + valor (magnitude).
class DomainBarDatum {
  const DomainBarDatum({required this.label, required this.value});

  final String label;
  final double value;
}

/// Barras horizontais de magnitude, matiz única.
///
/// A identidade de cada barra vem do rótulo do eixo, nunca da cor - a cor
/// aqui é só magnitude (regra 1 de `chart_tokens.dart`): quanto maior o
/// valor, mais claro o passo da rampa sequencial. Ordena sempre por valor,
/// decrescente por padrão, independente da ordem recebida - ou crescente
/// quando [ascending] é verdadeiro (ex.: pior nota primeiro, quando "maior
/// valor" não significa "pior").
class DomainBarChart extends StatelessWidget {
  const DomainBarChart({
    super.key,
    required this.data,
    this.maxValue = 100,
    this.peerMedian,
    this.valueSuffix = '',
    this.selectedLabel,
    this.onSelect,
    this.valueLabelBuilder,
    this.valueColumnWidth = 40,
    this.ascending = false,
  });

  final List<DomainBarDatum> data;

  /// Teto da escala (o índice de postura do produto vai de 0 a 100).
  final double maxValue;

  /// Marcador vertical opcional para a mediana do setor.
  final double? peerMedian;

  final String valueSuffix;

  /// Rótulo da barra atualmente selecionada (drill-down), se houver.
  final String? selectedLabel;

  /// Quando fornecido, cada barra vira um alvo de toque que seleciona seu
  /// domínio (ex.: para um botão "ver compliance" filtrar por ele). `null`
  /// mantém o gráfico puramente informativo, como antes.
  final ValueChanged<String>? onSelect;

  /// Formata o rótulo de valor de cada barra. `null` mantém o padrão
  /// (`toStringAsFixed(0)` + [valueSuffix]) - use quando o valor não é uma
  /// nota de 0 a 100 (ex.: moeda), para exibir "R$ 4,2 mi" em vez de um
  /// número bruto de sete dígitos.
  final String Function(double value)? valueLabelBuilder;

  /// Largura da coluna de valor, à direita de cada barra. O padrão (40)
  /// serve para notas de 2-3 dígitos; rótulos formatados (moeda) costumam
  /// precisar de mais espaço.
  final double valueColumnWidth;

  /// Quando verdadeiro, ordena do menor valor para o maior (ex.: pior nota
  /// de postura primeiro). Padrão `false` (maior primeiro), correto quando
  /// "maior" já significa "pior" (ex.: exposição financeira).
  final bool ascending;

  Color _colorForValue(BuildContext context, double value) {
    final Brightness brightness = Theme.of(context).brightness;
    final List<Color> ramp = ChartTokens.sequentialFor(brightness);
    final double t =
        maxValue <= 0 ? 0 : (value / maxValue).clamp(0, 1).toDouble();
    final double scaled = t * (ramp.length - 1);
    final int lowerIndex = scaled.floor().clamp(0, ramp.length - 1).toInt();
    final int upperIndex = scaled.ceil().clamp(0, ramp.length - 1).toInt();
    final double fraction = scaled - lowerIndex;
    return Color.lerp(ramp[lowerIndex], ramp[upperIndex], fraction) ??
        ramp[lowerIndex];
  }

  String _labelFor(double value) =>
      valueLabelBuilder?.call(value) ?? '${value.toStringAsFixed(0)}$valueSuffix';

  String _semanticLabel() {
    if (data.isEmpty) {
      return 'Sem dados por domínio.';
    }
    final List<DomainBarDatum> sortedForLabel = List<DomainBarDatum>.of(data)
      ..sort(
        (DomainBarDatum a, DomainBarDatum b) => ascending
            ? a.value.compareTo(b.value)
            : b.value.compareTo(a.value),
      );
    final String items = sortedForLabel
        .map((DomainBarDatum d) => '${d.label}: ${_labelFor(d.value)}')
        .join('; ');
    final String medianSuffix = peerMedian == null
        ? ''
        : ' Mediana do setor: ${_labelFor(peerMedian!)}.';
    final String order = ascending ? 'do menor para o maior' : 'do maior para o menor';
    return 'Valores por domínio, $order: $items.$medianSuffix';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    final List<DomainBarDatum> sorted = List<DomainBarDatum>.of(data)
      ..sort(
        (DomainBarDatum a, DomainBarDatum b) => ascending
            ? a.value.compareTo(b.value)
            : b.value.compareTo(a.value),
      );

    return Semantics(
      label: _semanticLabel(),
      container: true,
      // Quando o gráfico é selecionável, cada barra vira seu próprio alvo de
      // toque com `Semantics(button: true)` - excluir os descendentes aqui
      // apagaria esses botões. Sem `onSelect`, o gráfico é só informativo e o
      // rótulo composto acima já basta (mesma regra do `KpiTile`).
      excludeSemantics: onSelect == null,
      child: ChartReveal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (peerMedian != null) ...<Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 3,
                    height: 12,
                    color: ChartTokens.categoricalSlot2,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Mediana do setor (${_labelFor(peerMedian!)})',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final DomainBarDatum datum in sorted) ...<Widget>[
              _DomainBarRow(
                datum: datum,
                maxValue: maxValue,
                peerMedian: peerMedian,
                valueLabel: _labelFor(datum.value),
                valueColumnWidth: valueColumnWidth,
                color: _colorForValue(context, datum.value),
                selected: selectedLabel == datum.label,
                onTap: onSelect == null ? null : () => onSelect!(datum.label),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _DomainBarRow extends StatelessWidget {
  const _DomainBarRow({
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
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
