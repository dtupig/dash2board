import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../domain/request_driver.dart';
import '../wizard_draft.dart';

/// Passo 1 - por que a solicitação está sendo aberta.
class UseCaseStep extends StatelessWidget {
  const UseCaseStep({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.showErrors,
    required this.descriptionController,
  });

  final WizardDraft draft;
  final ValueChanged<WizardDraft> onChanged;
  final bool showErrors;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool missingDriver = showErrors && draft.driver == null;
    final bool missingDescription =
        showErrors && descriptionController.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Por que você está pedindo isso?',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Isso ajuda a Elytron a montar uma proposta com escopo certo desde '
          'a primeira versão.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final RequestDriver driver in RequestDriver.values)
              SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                selected: draft.driver == driver,
                accent: theme.colorScheme.primary,
                onTap: () => onChanged(draft.copyWith(driver: driver)),
                semanticLabel: driver.label,
                child: Text(driver.label),
              ),
          ],
        ),
        if (missingDriver)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Escolha um motivo.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          controller: descriptionController,
          label: 'Descreva em uma frase',
          hint: 'Ex.: novo aplicativo de pagamentos antes do lançamento',
        ),
        if (missingDescription)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Este campo é obrigatório.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}
