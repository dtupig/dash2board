import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/charts/chart_frame.dart';
import '../data/services_providers.dart';
import '../domain/contracted_service.dart';
import '../domain/service_category.dart';
import '../domain/service_catalog.dart';
import '../domain/service_offering.dart';
import 'widgets/catalog_category_group.dart';

/// Modo de exibição do catálogo - só o contratado, ou os 44 completos.
enum CatalogMode {
  reports('relatorios'),
  demand('demanda');

  const CatalogMode(this.wireValue);

  final String wireValue;

  static CatalogMode fromWire(String? value) =>
      value == demand.wireValue ? demand : reports;
}

/// Catálogo de serviços, com busca e agrupamento por categoria -
/// `/servicos/catalogo?modo=relatorios|demanda`.
class ServiceCatalogScreen extends ConsumerStatefulWidget {
  const ServiceCatalogScreen({super.key, required this.mode});

  final CatalogMode mode;

  @override
  ConsumerState<ServiceCatalogScreen> createState() =>
      _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends ConsumerState<ServiceCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _term = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openService(ServiceOffering offering, ContractedService? contract) {
    if (widget.mode == CatalogMode.reports) {
      context.push('/relatorios');
      return;
    }
    context.push('/servicos/demanda/${offering.serviceKey}');
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ContractedService>> contractedAsync =
        ref.watch(contractedServicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == CatalogMode.reports
              ? 'Relatórios por serviço'
              : 'Demandar um serviço',
        ),
      ),
      body: SafeArea(
        child: contractedAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: ChartFrame(
              title: 'Catálogo',
              height: 240,
              child: ChartLoading(),
            ),
          ),
          error: (Object error, StackTrace stackTrace) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ChartFrame(
              title: 'Catálogo',
              height: 200,
              child: ChartError(
                message: 'Não foi possível carregar os serviços contratados.',
                onRetry: () => ref.invalidate(contractedServicesProvider),
              ),
            ),
          ),
          data: (List<ContractedService> contracted) => _buildBody(contracted),
        ),
      ),
    );
  }

  Widget _buildBody(List<ContractedService> contracted) {
    final Map<String, ContractedService> byKey = <String, ContractedService>{
      for (final ContractedService c in contracted) c.serviceKey: c,
    };

    List<ServiceOffering> visible = ServiceCatalog.search(_term);
    if (widget.mode == CatalogMode.reports) {
      visible = visible
          .where((ServiceOffering s) => byKey.containsKey(s.serviceKey))
          .toList(growable: false);
    }

    if (widget.mode == CatalogMode.reports && contracted.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ChartFrame(
          title: 'Relatórios',
          height: 200,
          child: ChartEmpty(
            message: 'Sua empresa ainda não contratou nenhum serviço - por '
                'isso não há relatório para mostrar aqui.',
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        TextField(
          controller: _searchController,
          onChanged: (String value) => setState(() => _term = value),
          decoration: const InputDecoration(
            hintText: 'Buscar por serviço ou categoria',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: ChartEmpty(message: 'Nenhum serviço encontrado.'),
          )
        else
          for (final ServiceCategory category in ServiceCategory.values)
            CatalogCategoryGroup(
              category: category,
              services: visible
                  .where((ServiceOffering s) => s.category == category)
                  .toList(growable: false)
                ..sort((ServiceOffering a, ServiceOffering b) {
                  final bool aContracted = byKey.containsKey(a.serviceKey);
                  final bool bContracted = byKey.containsKey(b.serviceKey);
                  if (aContracted != bContracted) {
                    return aContracted ? -1 : 1;
                  }
                  return a.label.compareTo(b.label);
                }),
              byKey: byKey,
              onOpen: _openService,
            ),
      ],
    );
  }
}
