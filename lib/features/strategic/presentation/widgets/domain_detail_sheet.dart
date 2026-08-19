import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/charts/chart_frame.dart';
import '../../../../core/widgets/charts/delta_badge.dart';
import '../../data/strategic_providers.dart';
import '../../domain/compliance_control.dart';
import '../../domain/security_domain.dart';
import '../compliance_formatting.dart';
import '../compliance_visuals.dart';

/// Detalhe de um domínio de controle, aberto ao tocar em uma barra de
/// `domain_risk_section.dart`: nota, variação em 30 dias, comparação com a
/// mediana do setor e os controles de compliance em `gap` que explicam a
/// nota - com um atalho direto para a tela de compliance já filtrada.
class DomainDetailSheet extends ConsumerWidget {
  const DomainDetailSheet({
    super.key,
    required this.domain,
    required this.score,
    required this.delta30d,
    required this.peerMedian,
  });

  final SecurityDomain domain;
  final int score;
  final int delta30d;
  final int peerMedian;

  void _viewCompliance(BuildContext context) {
    // Fecha a folha antes de navegar - caminho literal em vez de importar
    // `app/router.dart` (mesmo motivo do restante do painel: evita import
    // circular entre o roteador e as telas que ele registra). Mantenha em
    // sincronia com `AppRoute.strategicCompliance`.
    Navigator.of(context).pop();
    context.go('/estrategia/compliance?domain=${domain.wireValue}');
  }

  String _peerSentence() {
    final int diff = score - peerMedian;
    if (diff > 0) {
      return '$diff pontos acima da mediana do setor';
    }
    if (diff < 0) {
      return '${diff.abs()} pontos abaixo da mediana do setor';
    }
    return 'empatado com a mediana do setor';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AsyncValue<List<ComplianceControl>> complianceAsync =
        ref.watch(complianceProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scrollController) {
        return SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  domain.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    '$score',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'pontos',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              DeltaBadge(
                value: delta30d,
                unitLabel: 'pontos',
                periodLabel: 'em 30 dias',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Comparado ao setor, este domínio está ${_peerSentence()}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                header: true,
                child: Text(
                  'Controles em lacuna',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              complianceAsync.when(
                loading: () =>
                    const SizedBox(height: 96, child: ChartLoading()),
                error: (Object error, StackTrace stackTrace) => ChartError(
                  message: 'Não foi possível carregar os controles agora.',
                  onRetry: () => ref.invalidate(complianceProvider),
                ),
                data: (List<ComplianceControl> controls) {
                  final List<ComplianceControl> gaps = controls
                      .where(
                        (ComplianceControl c) =>
                            c.domain == domain && c.status == ControlStatus.gap,
                      )
                      .toList(growable: false);
                  if (gaps.isEmpty) {
                    return const ChartEmpty(
                      message: 'Nenhum controle em lacuna neste domínio.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final ComplianceControl control in gaps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _GapControlRow(control: control),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => _viewCompliance(context),
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: Text('Ver compliance de ${domain.label}'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GapControlRow extends StatelessWidget {
  const _GapControlRow({required this.control});

  final ComplianceControl control;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Semantics(
      label: '${control.controlId}, ${control.title}, responsável '
          '${control.ownerName}, revisado em '
          '${formatDatePtBr(control.lastReviewedAt)}.',
      container: true,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(control.status.icon, size: 18, color: control.status.color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  control.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${control.ownerName} · revisado em '
                  '${formatDatePtBr(control.lastReviewedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
