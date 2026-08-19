import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/charts/chart_frame.dart';
import '../../../../core/widgets/charts/domain_bar_chart.dart';
import '../../data/strategic_providers.dart';
import '../../domain/posture_index.dart';
import '../../domain/security_domain.dart';
import 'domain_detail_sheet.dart';

/// Bloco 3 do painel do CISO: "Onde está o risco" - responde a segunda
/// frase do comitê ("o problema está concentrado em..."). O pior domínio
/// aparece primeiro, porque é sobre ele que a conversa vai acontecer.
class DomainRiskSection extends ConsumerWidget {
  const DomainRiskSection({super.key});

  void _openDetail(
    BuildContext context,
    PostureIndex index,
    SecurityDomain domain,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => DomainDetailSheet(
        domain: domain,
        score: index.byDomain[domain] ?? 0,
        delta30d: index.byDomainDelta30d[domain] ?? 0,
        peerMedian: index.peerMedian,
      ),
    );
  }

  Widget _table(BuildContext context, PostureIndex index) {
    final List<MapEntry<SecurityDomain, int>> sorted = index.byDomain.entries
        .toList(growable: false)
      ..sort(
        (MapEntry<SecurityDomain, int> a, MapEntry<SecurityDomain, int> b) =>
            a.value.compareTo(b.value),
      );
    return SizedBox(
      height: 280,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: sorted.length,
        itemBuilder: (BuildContext context, int i) {
          final MapEntry<SecurityDomain, int> entry = sorted[i];
          return ListTile(
            title: Text(entry.key.label),
            trailing: Text('${entry.value} pontos'),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PostureIndex> indexAsync = ref.watch(postureIndexProvider);
    final PostureIndex? index = indexAsync.value;

    return ChartFrame(
      title: 'Onde está o risco',
      subtitle: 'índice por domínio de controle - toque para ver os '
          'controles em lacuna',
      height: 280,
      onShowTable: (index == null || index.byDomain.isEmpty)
          ? null
          : (BuildContext sheetContext) => _table(sheetContext, index),
      child: indexAsync.when(
        loading: () => const ChartLoading(),
        error: (Object error, StackTrace stackTrace) => ChartError(
          message: 'Não foi possível carregar a postura por domínio agora.',
          onRetry: () => ref.invalidate(postureIndexProvider),
        ),
        data: (PostureIndex data) {
          if (data.byDomain.isEmpty) {
            return const ChartEmpty(
              message: 'Ainda não há dados de postura por domínio.',
            );
          }

          final List<DomainBarDatum> bars = <DomainBarDatum>[
            for (final MapEntry<SecurityDomain, int> entry
                in data.byDomain.entries)
              DomainBarDatum(
                  label: entry.key.label, value: entry.value.toDouble()),
          ];

          return DomainBarChart(
            data: bars,
            peerMedian: data.peerMedian.toDouble(),
            ascending: true,
            onSelect: (String label) {
              final SecurityDomain domain = data.byDomain.keys
                  .firstWhere((SecurityDomain d) => d.label == label);
              _openDetail(context, data, domain);
            },
          );
        },
      ),
    );
  }
}
