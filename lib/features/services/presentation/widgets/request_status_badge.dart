import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/request_status.dart';

/// Selo de status de uma [ServiceRequest] - cor de estado (não de
/// severidade, que é reservada para o kit de gráficos) + rótulo em pt-BR,
/// nunca só cor.
class RequestStatusBadge extends StatelessWidget {
  const RequestStatusBadge({super.key, required this.status});

  final RequestStatus status;

  Color _colorFor(ColorScheme scheme) => switch (status) {
        RequestStatus.draft => scheme.outline,
        RequestStatus.pendingApproval => scheme.tertiary,
        RequestStatus.approved => scheme.primary,
        RequestStatus.rejected => scheme.error,
        RequestStatus.sentToElytron => scheme.primary,
        RequestStatus.proposalReceived => scheme.tertiary,
        RequestStatus.contracted => scheme.primary,
        RequestStatus.delivered => scheme.primary,
        RequestStatus.cancelled => scheme.outline,
      };

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = _colorFor(scheme);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
