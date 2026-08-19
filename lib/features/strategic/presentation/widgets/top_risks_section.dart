import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/charts/chart_frame.dart';
import '../../../../core/widgets/charts/severity_chip.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../data/strategic_providers.dart';
import '../../domain/risk_item.dart';
import '../briefing_formatting.dart';

/// Um `residualScore` (0-100, depois dos controles em vigor) vira severidade
/// visual - o mesmo vocabulário usado em toda a carteira de risco.
ChartSeverityLevel _severityFor(int residualScore) {
  if (residualScore >= 80) {
    return ChartSeverityLevel.critical;
  }
  if (residualScore >= 55) {
    return ChartSeverityLevel.high;
  }
  if (residualScore >= 30) {
    return ChartSeverityLevel.medium;
  }
  return ChartSeverityLevel.low;
}

/// Bloco 4 do painel do CISO: até 5 riscos de negócio de maior exposição
/// financeira, em linguagem executiva - não é uma lista técnica de
/// vulnerabilidades, é o que o comitê decidiria sobre.
class TopRisksSection extends ConsumerWidget {
  const TopRisksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<RiskItem>> risksAsync = ref.watch(topRisksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Top riscos de negócio',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        risksAsync.when(
          loading: () => const SizedBox(height: 96, child: ChartLoading()),
          error: (Object error, StackTrace stackTrace) => ChartError(
            message:
                'Não foi possível carregar os riscos de negócio agora.',
            onRetry: () => ref.invalidate(topRisksProvider),
          ),
          data: (List<RiskItem> risks) {
            if (risks.isEmpty) {
              return const ChartEmpty(
                message: 'Nenhum risco de negócio cadastrado ainda.',
              );
            }
            return Column(
              children: <Widget>[
                for (final RiskItem risk in risks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _TopRiskCard(risk: risk),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TopRiskCard extends StatelessWidget {
  const _TopRiskCard({required this.risk});

  final RiskItem risk;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ChartSeverityLevel severity = _severityFor(risk.residualScore);

    return SurfaceCard(
      semanticLabel: '${risk.title}, unidade ${risk.businessUnit}, '
          'severidade ${severity.label}, perda anual esperada '
          '${formatCurrencyCompactBrl(risk.annualLossExpectancy)}.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    risk.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SeverityChip(level: severity),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              risk.businessUnit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Perda anual esperada: '
              '${formatCurrencyCompactBrl(risk.annualLossExpectancy)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
