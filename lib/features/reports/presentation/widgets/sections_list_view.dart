import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../auth/domain/user_role.dart';
import '../../domain/action_item.dart';
import '../../domain/report.dart';
import '../../domain/report_section.dart';
import 'report_header.dart';
import 'report_section_tile.dart';

/// Corpo compartilhado das visões `operational` e `strategic`: cabeçalho,
/// todas as seções (cada uma decide por si, via `ReportSectionTile`, se
/// mostra o conteúdo ou o aviso de supressão) e o plano de ação.
///
/// A diferença entre as duas personas não está neste widget - está em
/// *quais* seções `ReportAccessPolicy.canSeeSection` libera para [role].
class SectionsListView extends StatelessWidget {
  const SectionsListView({
    super.key,
    required this.report,
    required this.sections,
    required this.role,
  });

  final ServiceReport report;
  final List<ReportSection> sections;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.screenPadding,
      children: <Widget>[
        ReportHeader(report: report),
        const SizedBox(height: AppSpacing.lg),
        for (final ReportSection section in sections) ...<Widget>[
          ReportSectionTile(
            section: section,
            role: role,
            classification: report.classification,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (report.nextSteps.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text('Plano de ação', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final ActionItem action in report.nextSteps)
            SurfaceCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                '${action.title} — ${action.ownerName} '
                '(${action.priority.label})',
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ],
    );
  }
}
