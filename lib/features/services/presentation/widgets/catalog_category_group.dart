import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/contracted_service.dart';
import '../../domain/service_category.dart';
import '../../domain/service_offering.dart';
import 'service_offering_card.dart';

/// Um grupo de serviços de uma categoria do catálogo, com contagem no
/// cabeçalho - não renderiza nada quando a categoria não tem serviço visível
/// (ex.: filtrado pela busca ou pelo modo "relatórios").
class CatalogCategoryGroup extends StatelessWidget {
  const CatalogCategoryGroup({
    super.key,
    required this.category,
    required this.services,
    required this.byKey,
    required this.onOpen,
  });

  final ServiceCategory category;
  final List<ServiceOffering> services;
  final Map<String, ContractedService> byKey;
  final void Function(ServiceOffering, ContractedService?) onOpen;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              '${category.label} (${services.length})',
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final ServiceOffering offering in services)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ServiceOfferingCard(
                offering: offering,
                isContracted: byKey.containsKey(offering.serviceKey),
                lastDeliveryAt: byKey[offering.serviceKey]?.lastDeliveryAt,
                onTap: () => onOpen(offering, byKey[offering.serviceKey]),
              ),
            ),
        ],
      ),
    );
  }
}
