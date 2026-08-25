import 'package:flutter/material.dart';

/// Pergunta se o usuário quer salvar o rascunho, descartar ou cancelar a
/// saída do wizard. `true` quando a saída deve prosseguir (salvando ou
/// descartando); `false` quando o usuário cancelou.
Future<bool> confirmWizardExit(
  BuildContext context, {
  required Future<void> Function() onSave,
  required Future<void> Function() onDiscard,
}) async {
  final String? choice = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Sair do wizard?'),
      content: const Text(
        'Você pode salvar o que já preencheu e continuar depois, ou '
        'descartar tudo.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop('cancel'),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop('discard'),
          child: const Text('Descartar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop('save'),
          child: const Text('Salvar rascunho'),
        ),
      ],
    ),
  );
  if (choice == 'discard') {
    await onDiscard();
    return true;
  }
  if (choice == 'save') {
    await onSave();
    return true;
  }
  return false;
}
