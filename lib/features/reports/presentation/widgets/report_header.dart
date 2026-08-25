import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/report.dart';
import '../reports_formatting.dart';
import 'classification_badge.dart';

/// Cabeçalho comum às três visões: serviço, período, versão, responsável
/// Elytron, selo de classificação e, quando houver, o selo de fato
/// relevante.
class ReportHeader extends StatelessWidget {
  const ReportHeader({super.key, required this.report});

  final ServiceReport report;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ClassificationBadge(classification: report.classification),
            if (report.hasMaterialFact)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.priority_high_rounded,
                        size: 14, color: scheme.error),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'Fato relevante',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(report.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${report.referencePeriod} · versão ${report.version} · '
          '${report.elytronLeadName}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          'Entregue em ${formatReportDatePtBr(report.deliveredAt)}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
