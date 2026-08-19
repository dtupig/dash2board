import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/charts/chart_frame.dart';
import '../../../../core/widgets/charts/delta_badge.dart';
import '../../../../core/widgets/charts/kpi_tile.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../data/strategic_providers.dart';
import '../../domain/posture_index.dart';
import '../../domain/posture_snapshot.dart';

/// Bloco 1 do painel do CISO: o "hero number" que responde, sozinho, a
/// primeira das três frases que o comitê precisa ouvir ("nossa postura está
/// em X, subiu/caiu Y no ano"). Nunca vira gráfico - é só `KpiTile`.
class PostureHeadline extends ConsumerWidget {
  const PostureHeadline({super.key});

  static const double _height = 168;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PostureIndex> indexAsync = ref.watch(postureIndexProvider);
    final AsyncValue<List<PostureSnapshot>> historyAsync =
        ref.watch(postureHistoryProvider);

    // `hasError` vem ANTES de `isLoading`: um `AsyncValue` pode carregar os
    // dois ao mesmo tempo (Riverpod preserva o erro anterior durante um novo
    // carregamento, ex.: após `ref.invalidate`) - se checássemos `isLoading`
    // primeiro, uma falha logo no primeiro carregamento ficaria presa no
    // esqueleto para sempre, sem nunca mostrar "tentar de novo".
    if (indexAsync.hasError || historyAsync.hasError) {
      return SurfaceCard(
        child: SizedBox(
          height: _height,
          child: ChartError(
            message: 'Não foi possível carregar o índice de postura agora.',
            onRetry: () {
              ref.invalidate(postureIndexProvider);
              ref.invalidate(postureHistoryProvider);
            },
          ),
        ),
      );
    }

    if (indexAsync.isLoading || historyAsync.isLoading) {
      return const SurfaceCard(
        child: SizedBox(height: _height, child: ChartLoading()),
      );
    }

    final PostureIndex index = indexAsync.requireValue;
    final List<PostureSnapshot> history = historyAsync.requireValue;

    if (index.byDomain.isEmpty) {
      return const SurfaceCard(
        child: SizedBox(
          height: _height,
          child: ChartEmpty(
            message: 'Ainda não há índice de postura calculado.',
          ),
        ),
      );
    }

    // Variação em 12 meses (o que a primeira frase do comitê exige) - não é
    // `index.delta`, que é mês a mês. Sem histórico suficiente, cai para a
    // variação mês a mês como aproximação segura em vez de esconder o selo.
    final int delta12mo = history.isNotEmpty
        ? index.overallScore - history.first.score
        : index.delta;

    final int peerDiff = index.overallScore - index.peerMedian;
    final String peerSentence = peerDiff > 0
        ? '$peerDiff pontos acima da mediana do setor'
        : peerDiff < 0
            ? '${peerDiff.abs()} pontos abaixo da mediana do setor'
            : 'empatado com a mediana do setor';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        KpiTile(
          label: 'Índice de postura',
          value: '${index.overallScore}',
          unit: 'pontos',
          delta: DeltaBadge(
            value: delta12mo,
            unitLabel: 'pontos',
            periodLabel: 'em 12 meses',
          ),
          sparklineValues: <double>[
            for (final PostureSnapshot snapshot in history)
              snapshot.score.toDouble(),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            'Comparado ao setor, estamos $peerSentence.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
