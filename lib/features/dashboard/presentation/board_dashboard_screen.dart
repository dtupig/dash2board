import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/charts/chart_frame.dart';
import '../../../core/widgets/charts/delta_badge.dart';
import '../../../core/widgets/charts/domain_bar_chart.dart';
import '../../../core/widgets/surface_card.dart';
import '../../auth/domain/user_role.dart';
import '../../shell/persona_scaffold.dart';
import '../../strategic/data/strategic_providers.dart';
import '../../strategic/domain/risk_item.dart';
import '../../strategic/domain/tenant_profile.dart';
import '../../strategic/presentation/briefing_formatting.dart';
import '../../strategic/presentation/compliance_formatting.dart';

/// Persona 3 - Board e executivos C-Level das unidades de negócio.
///
/// A regra que governa esta tela: zero jargão. Se um termo técnico é
/// indispensável, ele vem explicado na mesma linha, em linguagem de
/// negócio. Nada de índice de postura, domínio de controle, framework de
/// compliance, CVE, incidente ou nome de ferramenta - se o board quiser
/// detalhe técnico, ele chama o CISO.
class BoardDashboardScreen extends ConsumerWidget {
  const BoardDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const UserRole role = UserRole.board;
    final AsyncValue<List<RiskItem>> risksAsync = ref.watch(allRisksProvider);
    final AsyncValue<TenantProfile> profileAsync =
        ref.watch(tenantProfileProvider);

    void retryAll() {
      ref.invalidate(allRisksProvider);
      ref.invalidate(tenantProfileProvider);
    }

    Widget body;
    // `hasError` vem ANTES de `isLoading`: um `AsyncValue` pode carregar os
    // dois ao mesmo tempo (Riverpod preserva o erro anterior durante um novo
    // carregamento) - checar `isLoading` primeiro deixaria uma falha logo no
    // primeiro carregamento presa no esqueleto para sempre, sem nunca
    // mostrar "tentar de novo".
    if (risksAsync.hasError || profileAsync.hasError) {
      body = _BoardErrorBody(onRetry: retryAll);
    } else if (risksAsync.isLoading || profileAsync.isLoading) {
      body = const _BoardLoadingBody();
    } else {
      body = _BoardBody(
        risks: risksAsync.requireValue,
        profile: profileAsync.requireValue,
      );
    }

    return PersonaScaffold(
      role: role,
      title: 'Risco Cibernético do Negócio',
      subtitle:
          'Três números, uma tendência e as decisões que dependem do board.',
      children: <Widget>[body],
    );
  }
}

class _BoardLoadingBody extends StatelessWidget {
  const _BoardLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        ChartFrame(
          title: 'Exposição financeira estimada',
          height: 120,
          child: ChartLoading(),
        ),
        SizedBox(height: AppSpacing.xl),
        ChartFrame(
          title: 'Impacto por unidade de negócio',
          height: 220,
          child: ChartLoading(),
        ),
      ],
    );
  }
}

class _BoardErrorBody extends StatelessWidget {
  const _BoardErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ChartFrame(
      title: 'Risco do negócio',
      height: 220,
      child: ChartError(
        message: 'Não foi possível carregar os números de risco agora.',
        onRetry: onRetry,
      ),
    );
  }
}

class _BoardBody extends ConsumerWidget {
  const _BoardBody({required this.risks, required this.profile});

  final List<RiskItem> risks;
  final TenantProfile profile;

  Map<String, double> _aleByBusinessUnit() {
    final Map<String, double> byBu = <String, double>{};
    for (final RiskItem risk in risks) {
      byBu[risk.businessUnit] =
          (byBu[risk.businessUnit] ?? 0) + risk.annualLossExpectancy;
    }
    return byBu;
  }

  void _openBusinessUnitSheet(BuildContext context, String businessUnit) {
    final List<RiskItem> unitRisks = risks
        .where((RiskItem r) => r.businessUnit == businessUnit)
        .toList(growable: false)
      ..sort((RiskItem a, RiskItem b) =>
          b.annualLossExpectancy.compareTo(a.annualLossExpectancy));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => _BusinessUnitRisksSheet(
        businessUnit: businessUnit,
        ownerName: profile.ownerFor(businessUnit),
        risks: unitRisks,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (risks.isEmpty) {
      return const ChartFrame(
        title: 'Risco do negócio',
        height: 200,
        child: ChartEmpty(
          message: 'Nenhum risco de negócio cadastrado ainda.',
        ),
      );
    }

    final Map<String, double> aleByBu = _aleByBusinessUnit();
    final double totalAle =
        aleByBu.values.fold(0.0, (double sum, double v) => sum + v);
    final double maxBuAle = aleByBu.values.isEmpty
        ? 1
        : aleByBu.values.reduce((double a, double b) => a > b ? a : b);
    final double percentOfRevenue = profile.annualRevenue <= 0
        ? 0
        : (totalAle / profile.annualRevenue) * 100;
    final double quarterlyDelta = totalAle - profile.previousQuarterAle;
    final List<RiskItem> pending = risks
        .where((RiskItem r) => r.acceptance == RiskAcceptance.pending)
        .toList(growable: false)
      ..sort(
          (RiskItem a, RiskItem b) => a.reviewDueAt.compareTo(b.reviewDueAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Bloco 1 - exposição financeira (hero number).
        SurfaceCard(
          semanticLabel:
              'Exposição financeira estimada: ${formatCurrencyBrl(totalAle)}, '
              '${percentOfRevenue.toStringAsFixed(1)} por cento da receita '
              'anual.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Exposição financeira estimada',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      formatCurrencyBrl(totalAle),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${percentOfRevenue.toStringAsFixed(1)}% da receita anual',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DeltaBadge(
                value: quarterlyDelta,
                unitLabel: '',
                periodLabel: 'no trimestre',
                invertPolarity: true,
                magnitudeFormatter: formatCurrencyCompactBrl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Este número é a perda que a empresa esperaria sofrer por ano '
                'se nada mudar nos riscos abertos hoje, somando a chance de '
                'cada um acontecer com o quanto custaria. Vem dos riscos '
                'cadastrados pela área de segurança.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Bloco 2 - impacto por unidade de negócio.
        ChartFrame(
          title: 'Impacto por unidade de negócio',
          subtitle:
              'Toque em uma unidade para ver os riscos por trás do número.',
          height: 76.0 * aleByBu.length + 24,
          onShowTable: (BuildContext sheetContext) => _businessUnitTable(
            sheetContext,
            aleByBu,
          ),
          child: DomainBarChart(
            data: <DomainBarDatum>[
              for (final MapEntry<String, double> entry in aleByBu.entries)
                DomainBarDatum(label: entry.key, value: entry.value),
            ],
            maxValue: maxBuAle,
            valueLabelBuilder: formatCurrencyCompactBrl,
            valueColumnWidth: 68,
            onSelect: (String bu) => _openBusinessUnitSheet(context, bu),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // "Ao lado de cada unidade, o nome do executivo responsável" - a
        // barra acima já não tem espaço para o nome completo do executivo,
        // então a lista abaixo faz o pareamento explícito unidade -> dono.
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final String bu in aleByBu.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '$bu — ${profile.ownerFor(bu)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Bloco 3 - decisões pendentes do board.
        Semantics(
          header: true,
          child: Text(
            'Decisões pendentes do board',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (pending.isEmpty)
          const SurfaceCard(
            semanticLabel: 'Nenhuma decisão pendente no momento. Boa notícia.',
            child: Row(
              children: <Widget>[
                Icon(Icons.check_circle_outline_rounded),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Nenhuma decisão pendente no momento - todos os riscos '
                    'abertos já têm um encaminhamento registrado.',
                  ),
                ),
              ],
            ),
          )
        else
          for (final RiskItem risk in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PendingDecisionCard(
                risk: risk,
                ownerName: profile.ownerFor(risk.businessUnit),
              ),
            ),
      ],
    );
  }

  Widget _businessUnitTable(BuildContext context, Map<String, double> aleByBu) {
    final List<MapEntry<String, double>> sorted = aleByBu.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SizedBox(
      height: 280,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          for (final MapEntry<String, double> entry in sorted)
            ListTile(
              title: Text(entry.key),
              subtitle: Text(profile.ownerFor(entry.key)),
              trailing: Text(formatCurrencyBrl(entry.value)),
            ),
        ],
      ),
    );
  }
}

class _BusinessUnitRisksSheet extends StatelessWidget {
  const _BusinessUnitRisksSheet({
    required this.businessUnit,
    required this.ownerName,
    required this.risks,
  });

  final String businessUnit;
  final String ownerName;
  final List<RiskItem> risks;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
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
                  businessUnit,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                'Executivo responsável: $ownerName',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (risks.isEmpty)
                const ChartEmpty(
                  message: 'Nenhum risco aberto nesta unidade agora.',
                )
              else
                for (final RiskItem risk in risks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _RiskSummaryCard(risk: risk),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _RiskSummaryCard extends StatelessWidget {
  const _RiskSummaryCard({required this.risk});

  final RiskItem risk;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            risk.title,
            style:
                theme.textTheme.titleSmall?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Quanto custaria: ${formatCurrencyBrl(risk.annualLossExpectancy)} por ano, '
            'em média, se acontecer.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'O que está sendo feito: ${risk.treatment.label} · situação: '
            '${risk.acceptance.label}.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PendingDecisionCard extends ConsumerStatefulWidget {
  const _PendingDecisionCard({required this.risk, required this.ownerName});

  final RiskItem risk;
  final String ownerName;

  @override
  ConsumerState<_PendingDecisionCard> createState() =>
      _PendingDecisionCardState();
}

class _PendingDecisionCardState extends ConsumerState<_PendingDecisionCard> {
  bool _submitting = false;

  Future<void> _decide(RiskAcceptance decision) async {
    final String? note = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          _RiskDecisionDialog(risk: widget.risk, decision: decision),
    );
    if (note == null || !mounted) {
      return;
    }

    final String? tenantId = ref.read(appUserProvider).value?.tenantId;
    final String? uid = ref.read(appUserProvider).value?.uid;
    if (tenantId == null || uid == null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(strategicRepositoryProvider).recordRiskDecision(
            tenantId: tenantId,
            riskId: widget.risk.id,
            decision: decision,
            actorUid: uid,
            boardNote: note,
          );
      ref.invalidate(allRisksProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == RiskAcceptance.accepted
                ? 'Risco aceito e registrado.'
                : 'Plano de mitigação solicitado ao CISO.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível registrar a decisão agora.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final RiskItem risk = widget.risk;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            risk.title,
            style:
                theme.textTheme.titleSmall?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${risk.businessUnit} · ${widget.ownerName}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Prazo para decidir: ${formatDatePtBr(risk.reviewDueAt)}. Sem uma '
            'decisão registrada até lá, a exposição de '
            '${formatCurrencyBrl(risk.annualLossExpectancy)} por ano continua '
            'sem responsável nem plano formal.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => _decide(RiskAcceptance.planRequested),
                  child: const Text('Solicitar plano'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : () => _decide(RiskAcceptance.accepted),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Aceitar o risco'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskDecisionDialog extends StatefulWidget {
  const _RiskDecisionDialog({required this.risk, required this.decision});

  final RiskItem risk;
  final RiskAcceptance decision;

  @override
  State<_RiskDecisionDialog> createState() => _RiskDecisionDialogState();
}

class _RiskDecisionDialogState extends State<_RiskDecisionDialog> {
  final TextEditingController _noteController = TextEditingController();
  bool _hasNote = false;

  @override
  void initState() {
    super.initState();
    _noteController.addListener(() {
      final bool hasNote = _noteController.text.trim().isNotEmpty;
      if (hasNote != _hasNote) {
        setState(() => _hasNote = hasNote);
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAccepting = widget.decision == RiskAcceptance.accepted;
    final String explanation = isAccepting
        ? 'Você está aceitando conviver com uma exposição de '
            '${formatCurrencyBrl(widget.risk.annualLossExpectancy)} por ano '
            'até ${formatDatePtBr(widget.risk.reviewDueAt)}, quando este '
            'risco volta a ser revisado.'
        : 'Você está devolvendo este risco à área de segurança pedindo um '
            'plano de mitigação, com nova revisão prevista para '
            '${formatDatePtBr(widget.risk.reviewDueAt)}.';

    return AlertDialog(
      title:
          Text(isAccepting ? 'Aceitar risco' : 'Solicitar plano de mitigação'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(widget.risk.title,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          Text(explanation),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Justificativa (obrigatória)',
              hintText: 'Por que essa decisão faz sentido agora?',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _hasNote
              ? () => Navigator.of(context).pop(_noteController.text.trim())
              : null,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
