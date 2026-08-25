import 'package:flutter/material.dart';

/// Confirmação de aprovação - `null` cancela.
Future<bool> showApproveConfirmation(
  BuildContext context,
  String serviceLabel,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Aprovar solicitação?'),
      content: Text(
        '"$serviceLabel" será enviada à Elytron para virar proposta.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Aprovar'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Pede a nota obrigatória de rejeição - o botão de confirmar fica
/// desabilitado até haver texto. `null` quando o usuário cancela.
Future<String?> showRejectDialog(BuildContext context, String serviceLabel) {
  final TextEditingController controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final bool hasNote = controller.text.trim().isNotEmpty;
        return AlertDialog(
          title: const Text('Rejeitar solicitação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('"$serviceLabel" - explique o motivo para quem pediu.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Justificativa (obrigatória)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: hasNote
                  ? () =>
                      Navigator.of(dialogContext).pop(controller.text.trim())
                  : null,
              child: const Text('Rejeitar'),
            ),
          ],
        );
      },
    ),
  );
}
