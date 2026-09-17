import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../strategic/domain/risk_item.dart';
import '../../../strategic/presentation/briefing_formatting.dart';
import '../../../strategic/presentation/compliance_formatting.dart';

/// Diálogo de justificativa para aceitar um risco ou solicitar plano de
/// mitigação - exige uma nota antes de confirmar (trilha de auditoria
/// sempre tem "por quê"). Extraído de `board_pending_decisions_section.dart`
/// para manter aquele arquivo abaixo do limite de 250 linhas.
class BoardRiskDecisionDialog extends StatefulWidget {
  const BoardRiskDecisionDialog({
    super.key,
    required this.risk,
    required this.decision,
  });

  final RiskItem risk;
  final RiskAcceptance decision;

  @override
  State<BoardRiskDecisionDialog> createState() =>
      _BoardRiskDecisionDialogState();
}

class _BoardRiskDecisionDialogState extends State<BoardRiskDecisionDialog> {
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
