import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../domain/service_offering.dart';
import '../../services_formatting.dart';
import '../wizard_draft.dart';

/// Passo 5 - revisão completa, com "editar" em cada bloco.
class ReviewStep extends StatelessWidget {
  const ReviewStep({
    super.key,
    required this.offering,
    required this.draft,
    required this.onEditStep,
    required this.submitLabel,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final ServiceOffering offering;
  final WizardDraft draft;
  final ValueChanged<int> onEditStep;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Revise antes de enviar', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        _ReviewBlock(
          title: 'Caso de uso',
          onEdit: () => onEditStep(0),
          lines: <String>[
            draft.driver?.label ?? '-',
            draft.useCaseDescription,
          ],
        ),
        _ReviewBlock(
          title: 'Escopo',
          onEdit: () => onEditStep(1),
          lines: offering.requiresScopeAssets
              ? draft.scopeAssets
              : <String>[draft.volumeDescription],
        ),
        _ReviewBlock(
          title: 'Urgência e janela',
          onEdit: () => onEditStep(2),
          lines: <String>[
            draft.urgency?.label ?? '-',
            if (draft.desiredWindow != null)
              formatServiceDatePtBr(draft.desiredWindow!),
          ],
        ),
        _ReviewBlock(
          title: 'Justificativa de negócio',
          onEdit: () => onEditStep(3),
          lines: <String>[draft.justification],
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(submitLabel),
          ),
        ),
      ],
    );
  }
}

class _ReviewBlock extends StatelessWidget {
  const _ReviewBlock({
    required this.title,
    required this.lines,
    required this.onEdit,
  });

  final String title;
  final List<String> lines;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(title, style: theme.textTheme.titleSmall),
                ),
                TextButton(onPressed: onEdit, child: const Text('Editar')),
              ],
            ),
            for (final String line in lines.where((String l) => l.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  line,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
