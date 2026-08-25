import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../domain/request_status.dart';
import '../../domain/service_catalog.dart';
import '../../domain/service_request.dart';
import '../services_formatting.dart';
import 'request_status_badge.dart';

/// Quem está com a bola numa solicitação, em linguagem de negócio - usado
/// na lista de `operational` para saber com quem cobrar.
String requestOwnerLabel(RequestStatus status) => switch (status) {
      RequestStatus.draft => 'Com você - ainda não enviada',
      RequestStatus.pendingApproval => 'Com o CISO',
      RequestStatus.approved => 'Pronta para envio à Elytron',
      RequestStatus.rejected => 'Rejeitada pelo CISO',
      RequestStatus.sentToElytron => 'Com a Elytron',
      RequestStatus.proposalReceived => 'Proposta pronta para análise',
      RequestStatus.contracted => 'Contratada - aguardando entrega',
      RequestStatus.delivered => 'Entregue',
      RequestStatus.cancelled => 'Cancelada',
    };

/// Cartão de uma solicitação de serviço na fila de aprovação e na lista do
/// solicitante. [onApprove]/[onReject] só aparecem quando informados
/// (a tela decide, conforme `RequestPolicy`, quando isso faz sentido).
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
  });

  final ServiceRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String serviceLabel =
        ServiceCatalog.byKey(request.serviceKey)?.label ?? request.serviceKey;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(serviceLabel, style: theme.textTheme.titleSmall),
              ),
              const SizedBox(width: AppSpacing.sm),
              RequestStatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${request.requestedByName} · ${request.urgency.label} · '
            '${formatServiceDatePtBr(request.createdAt)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(request.scopeSummary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            requestOwnerLabel(request.status),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (request.approval?.note.isNotEmpty ?? false) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nota: ${request.approval!.note}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (onApprove != null || onReject != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Rejeitar'),
                    ),
                  ),
                if (onReject != null && onApprove != null)
                  const SizedBox(width: AppSpacing.md),
                if (onApprove != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      child: const Text('Aprovar'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
