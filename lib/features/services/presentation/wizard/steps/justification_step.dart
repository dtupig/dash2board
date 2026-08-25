import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Passo 4 - justificativa de negócio. É o que o CISO lê para aprovar.
class JustificationStep extends StatelessWidget {
  const JustificationStep({
    super.key,
    required this.controller,
    required this.showErrors,
  });

  final TextEditingController controller;
  final bool showErrors;

  static const int _maxLength = 500;

  static const List<String> _goodExamples = <String>[
    '"Achado crítico da auditoria externa de outubro exige teste de '
        'penetração antes da certificação PCI DSS."',
    '"Novo aplicativo de pagamentos processa dado de cartão e vai ao ar em '
        '45 dias - precisa de validação de segurança antes do lançamento."',
    '"Cliente âncora (30% da receita) exigiu laudo de pentest como condição '
        'contratual para renovação."',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool missing = showErrors && controller.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Justificativa de negócio', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'É o que o CISO vai ler para decidir se aprova.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: controller,
          maxLines: 5,
          maxLength: _maxLength,
          decoration: InputDecoration(
            hintText: 'Por que isso precisa acontecer agora?',
            border: const OutlineInputBorder(),
            errorText: missing ? 'Este campo é obrigatório.' : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Exemplos de boa justificativa',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        for (final String example in _goodExamples)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              example,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
