import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/chart_tokens.dart';
import '../../core/widgets/charts/chart_frame.dart';
import '../../core/widgets/charts/delta_badge.dart';
import '../../core/widgets/charts/domain_bar_chart.dart';
import '../../core/widgets/charts/kpi_tile.dart';
import '../../core/widgets/charts/severity_chip.dart';
import '../../core/widgets/charts/sparkline.dart';
import '../../core/widgets/charts/stacked_status_bar.dart';
import '../../core/widgets/charts/trend_line_chart.dart';

/// Galeria de gráficos - tela **temporária**, só para inspeção visual dos
/// widgets de `lib/core/widgets/charts/` nos dois temas.
///
/// Disponível apenas em modo de demonstração (`AppConfig.mockMode`), na rota
/// `/dev/graficos`. Não referenciada por nenhuma tela de produto.
class ChartGalleryScreen extends ConsumerWidget {
  const ChartGalleryScreen({super.key});

  static const List<double> _postureHistory = <double>[
    64, 65, 66, 67, 68, 69, 66, 65, 68, 70, 71, 72,
  ];

  static final List<DateTime> _trendTimestamps = List<DateTime>.generate(
    6,
    (int i) => DateTime.utc(2026, 3 + i, 1),
  );

  static const List<double> _ourOrgValues = <double>[64, 66, 68, 67, 70, 72];
  static const List<double> _peerMedianValues = <double>[68, 68, 68, 68, 68, 68];
  static const List<double> _targetValues = <double>[75, 75, 75, 75, 75, 75];

  static const List<DomainBarDatum> _domainData = <DomainBarDatum>[
    DomainBarDatum(label: 'Identidade', value: 81),
    DomainBarDatum(label: 'Endpoint', value: 76),
    DomainBarDatum(label: 'Nuvem', value: 63),
    DomainBarDatum(label: 'AppSec', value: 58),
    DomainBarDatum(label: 'Dados', value: 74),
    DomainBarDatum(label: 'Terceiros', value: 55),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeria de gráficos (dev)'),
        actions: <Widget>[
          Tooltip(
            message: themeMode == ThemeMode.dark
                ? 'Alternar para tema claro'
                : 'Alternar para tema escuro',
            child: IconButton(
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () =>
                  ref.read(themeModeProvider.notifier).toggle(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            const _SectionTitle('KpiTile'),
            const KpiTile(
              label: 'Índice de postura',
              value: '72',
              unit: 'pontos',
              delta: DeltaBadge(value: 1, periodLabel: 'em 30 dias'),
              sparklineValues: _postureHistory,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('DeltaBadge'),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                DeltaBadge(value: 8, periodLabel: 'em 30 dias'),
                DeltaBadge(value: -5, periodLabel: 'em 30 dias'),
                DeltaBadge(value: 0, periodLabel: 'em 30 dias'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Sparkline'),
            const SizedBox(
              height: 48,
              child: Sparkline(values: _postureHistory),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('TrendLineChart · 3 séries'),
            ChartFrame(
              title: 'Índice de postura',
              subtitle: 'Nossa organização, mediana do setor e meta',
              onShowTable: (BuildContext context) =>
                  _trendTable(context, _trendTimestamps),
              child: TrendLineChart(
                timestamps: _trendTimestamps,
                series: const <TrendSeries>[
                  TrendSeries(
                    label: 'Nossa organização',
                    values: _ourOrgValues,
                    color: ChartTokens.categoricalSlot1,
                  ),
                  TrendSeries(
                    label: 'Mediana do setor',
                    values: _peerMedianValues,
                    color: ChartTokens.categoricalSlot2,
                  ),
                  TrendSeries(
                    label: 'Meta',
                    values: _targetValues,
                    color: ChartTokens.categoricalSlot3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('DomainBarChart'),
            const ChartFrame(
              title: 'Postura por domínio',
              subtitle: 'Hoje, comparado à mediana do setor',
              height: 260,
              child: DomainBarChart(
                data: _domainData,
                peerMedian: 68,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('StackedStatusBar'),
            const StackedStatusBar(
              compliantCount: 13,
              partialCount: 6,
              gapCount: 5,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('SeverityChip'),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                SeverityChip(level: ChartSeverityLevel.critical),
                SeverityChip(level: ChartSeverityLevel.high),
                SeverityChip(level: ChartSeverityLevel.medium),
                SeverityChip(level: ChartSeverityLevel.low),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('ChartFrame · estados'),
            const ChartFrame(
              title: 'Carregando',
              height: 120,
              child: ChartLoading(),
            ),
            const SizedBox(height: AppSpacing.lg),
            ChartFrame(
              title: 'Vazio',
              height: 160,
              child: ChartEmpty(
                message: 'Nenhum controle de compliance cadastrado ainda.',
                actionLabel: 'Cadastrar controle',
                onAction: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ChartFrame(
              title: 'Erro',
              height: 160,
              child: ChartError(
                message: 'Não foi possível carregar os dados agora.',
                onRetry: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _trendTable(BuildContext context, List<DateTime> timestamps) {
    return SizedBox(
      height: 320,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          for (int i = 0; i < timestamps.length; i++)
            ListTile(
              title: Text('${timestamps[i].month}/${timestamps[i].year}'),
              subtitle: Text(
                'Nossa organização: ${_ourOrgValues[i].toStringAsFixed(0)} · '
                'Mediana: ${_peerMedianValues[i].toStringAsFixed(0)} · '
                'Meta: ${_targetValues[i].toStringAsFixed(0)}',
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
