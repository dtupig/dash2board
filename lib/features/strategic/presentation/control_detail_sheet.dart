import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/charts/severity_chip.dart';
import '../domain/compliance_control.dart';
import 'compliance_formatting.dart';
import 'compliance_visuals.dart';

/// Detalhe de um controle de compliance, aberto por
/// `showModalBottomSheet` + `DraggableScrollableSheet`.
///
/// Responde às duas perguntas do comitê: qual é o controle (título, dono,
/// última revisão) e qual é a evidência que sustenta o status - inclusive
/// quando a resposta é "nenhuma", que também é informação.
class ControlDetailSheet extends StatelessWidget {
  const ControlDetailSheet({super.key, required this.control});

  final ComplianceControl control;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final bool overdue =
        isReviewOverdue(control.lastReviewedAt, DateTime.now());

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Semantics(
                          header: true,
                          child: Text(
                            control.controlId,
                            style: textTheme.headlineSmall?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          control.framework.label,
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SeverityChip.custom(
                    icon: control.status.icon,
                    color: control.status.color,
                    label: control.status.label,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                control.title,
                style: textTheme.titleMedium?.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xl),
              _DetailSection(
                label: 'Responsável',
                child: Text(
                  control.ownerName,
                  style:
                      textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailSection(
                label: 'Última revisão',
                child: Row(
                  children: <Widget>[
                    Text(
                      formatDatePtBr(control.lastReviewedAt),
                      style: textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurface),
                    ),
                    if (overdue) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.event_busy_rounded,
                          size: 16, color: scheme.error),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        'prazo de revisão vencido',
                        style:
                            textTheme.labelSmall?.copyWith(color: scheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _DetailSection(
                label: 'Evidência',
                child: control.evidenceUrl == null
                    ? const _EmptyEvidence()
                    : _EvidenceLink(url: control.evidenceUrl!),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _EmptyEvidence extends StatelessWidget {
  const _EmptyEvidence();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: 'Este controle não tem evidência anexada.',
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: AppRadius.fieldRadius,
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.link_off_rounded,
                color: scheme.onSurfaceVariant, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Este controle não tem evidência anexada. Não há artefato '
                'registrado que sustente o status atual perante auditoria.',
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceLink extends StatelessWidget {
  const _EvidenceLink({required this.url});

  final String url;

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link da evidência copiado.')),
    );
    // TODO: abrir a evidência direto no navegador (url_launcher) fica para
    // um próximo prompt. Por ora, copiamos o link para a área de
    // transferência.
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SelectableText(
          url,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => unawaited(_copyLink(context)),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copiar link da evidência'),
        ),
      ],
    );
  }
}
