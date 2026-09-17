import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../strategic/data/strategic_providers.dart';
import '../../../strategic/domain/risk_item.dart';
import '../../../strategic/presentation/briefing_formatting.dart';
import '../../../strategic/presentation/compliance_formatting.dart';
import 'board_risk_decision_dialog.dart';

/// Bloco 3 do painel do board: decisões pendentes, com "aceitar o risco" ou
/// "solicitar plano" - a única escrita executiva do produto, sempre com
/// trilha de auditoria. Extraído de `board_dashboard_screen.dart`
/// (Bucket B) ao dar a HU-W-14 seu layout de tela larga.
///
/// [wide] troca a lista empilhada (`compact`/`medium`/`expanded`) por uma
/// grade que flui 2+ colunas (`large`, mesmo espírito do
/// `repeat(auto-fit,minmax(340px,1fr))` do mockup web) - mesmos cartões,
/// só a disposição muda.
class BoardPendingDecisionsSection extends StatelessWidget {
  const BoardPendingDecisionsSection({
    super.key,
    required this.pending,
    required this.ownerNameFor,
    this.wide = false,
  });

  final List<RiskItem> pending;
  final String Function(String businessUnit) ownerNameFor;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return const SurfaceCard(
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
      );
    }

    if (!wide) {
      return Column(
        children: <Widget>[
          for (final RiskItem risk in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PendingDecisionCard(
                risk: risk,
                ownerName: ownerNameFor(risk.businessUnit),
              ),
            ),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: <Widget>[
        for (final RiskItem risk in pending)
          SizedBox(
            width: 420,
            child: _PendingDecisionCard(
              risk: risk,
              ownerName: ownerNameFor(risk.businessUnit),
            ),
          ),
      ],
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
          BoardRiskDecisionDialog(risk: widget.risk, decision: decision),
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
