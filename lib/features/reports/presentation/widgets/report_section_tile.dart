import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../auth/domain/user_role.dart';
import '../../domain/report_access_policy.dart';
import '../../domain/report_classification.dart';
import '../../domain/report_section.dart';

/// Uma seção do relatório - mostra o conteúdo quando a política libera, ou
/// um aviso de supressão com o motivo (nunca some em silêncio).
class ReportSectionTile extends StatelessWidget {
  const ReportSectionTile({
    super.key,
    required this.section,
    required this.role,
    required this.classification,
  });

  final ReportSection section;
  final UserRole role;
  final ReportClassification classification;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool canSee = ReportAccessPolicy.canSeeSection(
      role,
      classification,
      section.sensitivity,
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (canSee)
            Text(section.body, style: theme.textTheme.bodyMedium)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.visibility_off_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    ReportAccessPolicy.redactionNotice(role),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
