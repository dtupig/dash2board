import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/report_classification.dart';

/// Selo de classificação - sempre cor de estado + ícone + rótulo, nunca só
/// cor (regra do kit de visualização).
class ClassificationBadge extends StatelessWidget {
  const ClassificationBadge({super.key, required this.classification});

  final ReportClassification classification;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color) = switch (classification) {
      ReportClassification.publicInternal => (
          Icons.public_rounded,
          scheme.onSurfaceVariant,
        ),
      ReportClassification.restricted => (
          Icons.lock_outline_rounded,
          scheme.tertiary
        ),
      ReportClassification.confidential => (
          Icons.shield_outlined,
          scheme.secondary,
        ),
      ReportClassification.secret => (Icons.gpp_maybe_outlined, scheme.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            classification.label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
