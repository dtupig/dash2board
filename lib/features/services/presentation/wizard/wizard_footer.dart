import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Rodapé comum dos passos 1 a 4 - "voltar" sempre disponível, "avançar"
/// valida o passo atual antes de seguir. O passo 5 (revisão) não usa este
/// rodapé: o botão final vive dentro de `ReviewStep`.
class WizardFooter extends StatelessWidget {
  const WizardFooter({
    super.key,
    required this.onBack,
    required this.onNext,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              child: const Text('Voltar'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: onNext,
              child: const Text('Avançar'),
            ),
          ),
        ],
      ),
    );
  }
}
