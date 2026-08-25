import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../domain/service_offering.dart';
import '../services_formatting.dart';

/// Cartão de um serviço do catálogo - usado tanto no modo "relatórios"
/// (mostra a última entrega) quanto no modo "demanda" (mostra o selo de
/// contratado/não contratado, nunca bloqueando o toque em nenhum dos dois
/// casos).
class ServiceOfferingCard extends StatelessWidget {
  const ServiceOfferingCard({
    super.key,
    required this.offering,
    required this.isContracted,
    required this.onTap,
    this.lastDeliveryAt,
  });

  final ServiceOffering offering;
  final bool isContracted;
  final VoidCallback onTap;

  /// Preenchido apenas no modo "relatórios".
  final DateTime? lastDeliveryAt;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String semantics = '${offering.label}. ${offering.shortPitch} '
        '${isContracted ? 'Contratado.' : 'Não contratado.'}'
        '${lastDeliveryAt != null ? ' Última entrega em ${formatServiceDatePtBr(lastDeliveryAt!)}.' : ''}';

    return SurfaceCard(
      onTap: onTap,
      semanticLabel: semantics,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    offering.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: scheme.onSurface),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ContractBadge(isContracted: isContracted),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              offering.shortPitch,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                Chip(
                  label: Text(offering.deliveryModel.label),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (lastDeliveryAt != null)
                  Chip(
                    avatar: const Icon(Icons.history_rounded, size: 16),
                    label: Text(
                      'Última entrega: ${formatServiceDatePtBr(lastDeliveryAt!)}',
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractBadge extends StatelessWidget {
  const _ContractBadge({required this.isContracted});

  final bool isContracted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = isContracted ? scheme.primary : scheme.outline;

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
        isContracted ? 'Contratado' : 'Não contratado',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
