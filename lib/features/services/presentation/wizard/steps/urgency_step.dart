import 'package:flutter/material.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../domain/request_urgency.dart';
import '../../services_formatting.dart';
import '../wizard_draft.dart';

/// Passo 3 - urgência e janela desejada. Selecionar `crisis` mostra o aviso
/// de que a RFS não substitui o acionamento do plantão DFIR - segurança de
/// verdade, não texto decorativo.
class UrgencyStep extends StatelessWidget {
  const UrgencyStep({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.showErrors,
    required this.onPickWindow,
  });

  final WizardDraft draft;
  final ValueChanged<WizardDraft> onChanged;
  final bool showErrors;
  final Future<void> Function() onPickWindow;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool missingUrgency = showErrors && draft.urgency == null;
    final bool missingWindow = showErrors && draft.desiredWindow == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Qual a urgência?', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        for (final RequestUrgency urgency in RequestUrgency.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SurfaceCard(
              selected: draft.urgency == urgency,
              accent: urgency == RequestUrgency.crisis ? scheme.error : null,
              onTap: () => onChanged(draft.copyWith(urgency: urgency)),
              semanticLabel: '${urgency.label}. ${urgency.slaDescription}',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(urgency.label, style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      urgency.slaDescription,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (missingUrgency)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Escolha uma urgência.',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
        if (draft.urgency == RequestUrgency.crisis)
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.sm, bottom: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.12),
                border: Border.all(color: scheme.error.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded, color: scheme.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Esta solicitação NÃO substitui o acionamento de '
                      'emergência. Se há um incidente em andamento agora, '
                      'ligue para o plantão DFIR: '
                      '${AppConfig.dfirEmergencyPhone}.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text('Janela desejada', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onPickWindow,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(
            draft.desiredWindow == null
                ? 'Escolher data'
                : formatServiceDatePtBr(draft.desiredWindow!),
          ),
        ),
        if (missingWindow)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Escolha a janela desejada.',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}
