import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/contracted_service.dart';
import '../../domain/service_offering.dart';

/// Substitui o visualizador de relatório (prompt 11, ainda não implementado)
/// enquanto ele não existe - mostra o que já se sabe sobre a entrega em vez
/// de abrir uma tela vazia.
class ReportsStubSheet extends StatelessWidget {
  const ReportsStubSheet({super.key, required this.offering, this.contract});

  final ServiceOffering offering;
  final ContractedService? contract;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(offering.label, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            if (contract != null) ...<Widget>[
              Text('Entregas recebidas: ${contract!.deliveriesCount}'),
              Text('Situação do contrato: ${contract!.status.label}'),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'O visualizador completo do relatório chega em uma próxima '
              'etapa do produto.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
