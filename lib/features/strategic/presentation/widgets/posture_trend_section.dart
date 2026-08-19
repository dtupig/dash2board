import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/chart_tokens.dart';
import '../../../../core/widgets/charts/chart_frame.dart';
import '../../../../core/widgets/charts/trend_line_chart.dart';
import '../../data/strategic_providers.dart';
import '../../domain/posture_snapshot.dart';

String _monthYear(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Bloco 2 do painel do CISO: "Evolução da postura" - a série de 12 meses
/// que sustenta a segunda e a terceira frase do comitê ("o problema está
/// concentrado em..." vem do bloco 3, mas a tendência geral vem daqui).
///
/// Duas séries fixas ("Nossa organização" e "Mediana do setor") - a terceira
/// série de `TrendLineChart` ("Meta") fica de fora porque o produto ainda
/// não modela uma meta de postura por tenant.
class PostureTrendSection extends ConsumerWidget {
  const PostureTrendSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PostureSnapshot>> historyAsync =
        ref.watch(postureHistoryProvider);
    final List<PostureSnapshot>? history = historyAsync.value;

    return ChartFrame(
      title: 'Evolução da postura',
      subtitle: 'últimos 12 meses',
      height: 240,
      onShowTable: (history == null || history.isEmpty)
          ? null
          : (BuildContext sheetContext) => _table(sheetContext, history),
      child: historyAsync.when(
        loading: () => const ChartLoading(),
        error: (Object error, StackTrace stackTrace) => ChartError(
          message:
              'Não foi possível carregar a evolução da postura agora.',
          onRetry: () => ref.invalidate(postureHistoryProvider),
        ),
        data: (List<PostureSnapshot> series) {
          if (series.isEmpty) {
            return const ChartEmpty(
              message: 'Ainda não há histórico de postura suficiente.',
            );
          }
          return TrendLineChart(
            // Índice de postura é sempre 0-100 - um eixo fixo evita que uma
            // escala automática exagere visualmente uma variação pequena.
            yAxisMin: 0,
            yAxisMax: 100,
            gridLineCount: 4,
            timestamps: <DateTime>[
              for (final PostureSnapshot s in series) s.capturedAt,
            ],
            series: <TrendSeries>[
              TrendSeries(
                label: 'Nossa organização',
                values: <double>[
                  for (final PostureSnapshot s in series) s.score.toDouble(),
                ],
                color: ChartTokens.categoricalSlot1,
              ),
              TrendSeries(
                label: 'Mediana do setor',
                values: <double>[
                  for (final PostureSnapshot s in series)
                    s.peerMedian.toDouble(),
                ],
                color: ChartTokens.categoricalSlot2,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _table(BuildContext context, List<PostureSnapshot> history) {
    return SizedBox(
      height: 320,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: history.length,
        itemBuilder: (BuildContext context, int index) {
          final PostureSnapshot snapshot = history[index];
          return ListTile(
            title: Text(_monthYear(snapshot.capturedAt)),
            trailing: Text(
              '${snapshot.score} pontos · mediana ${snapshot.peerMedian}',
            ),
          );
        },
      ),
    );
  }
}
