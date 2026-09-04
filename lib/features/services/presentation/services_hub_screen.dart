import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/surface_card.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/persona_visuals.dart';
import '../../shell/back_or_home_button.dart';
import '../data/services_providers.dart';
import '../domain/contracted_service.dart';
import '../domain/request_policy.dart';
import 'service_catalog_screen.dart';

/// Bifurcação do módulo de serviços - "ver relatórios" ou "demandar um
/// serviço" - `/servicos`. Acessível pelas três personas.
class ServicesHubScreen extends ConsumerWidget {
  const ServicesHubScreen({super.key});

  void _openReports(BuildContext context) {
    context.push('/servicos/catalogo?modo=${CatalogMode.reports.wireValue}');
  }

  void _openDemand(BuildContext context) {
    context.push('/servicos/catalogo?modo=${CatalogMode.demand.wireValue}');
  }

  void _explainDemandBlocked(BuildContext context, String reason) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserRole role =
        ref.watch(appUserProvider).value?.role ?? UserRole.pending;
    final AsyncValue<List<ContractedService>> contractedAsync =
        ref.watch(contractedServicesProvider);
    final int activeCount = contractedAsync.value
            ?.where((ContractedService c) => c.status == ContractStatus.active)
            .length ??
        0;

    final String? demandBlockReason =
        RequestPolicy.blockReason(role, RequestAction.open);

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: const Text('Serviços'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Text(
              '$activeCount ${activeCount == 1 ? 'serviço ativo' : 'serviços ativos'} '
              'no seu contrato.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SurfaceCard(
              accent: role.accent,
              onTap: () => _openReports(context),
              semanticLabel: 'Ver relatórios. Catálogo dos serviços que sua '
                  'empresa já contratou, com as entregas disponíveis.',
              child: const ExcludeSemantics(
                child: _HubChoiceContent(
                  icon: Icons.description_outlined,
                  title: 'Ver relatórios',
                  description:
                      'Os serviços que sua empresa já contratou, com as '
                      'entregas disponíveis.',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SurfaceCard(
              accent: demandBlockReason == null ? role.accent : null,
              onTap: demandBlockReason == null
                  ? () => _openDemand(context)
                  : () => _explainDemandBlocked(context, demandBlockReason),
              semanticLabel: 'Demandar um serviço. Catálogo completo dos 44 '
                  'serviços da Elytron.'
                  '${demandBlockReason != null ? ' Indisponível: $demandBlockReason' : ''}',
              child: ExcludeSemantics(
                child: _HubChoiceContent(
                  icon: Icons.add_circle_outline,
                  title: 'Demandar um serviço',
                  description: demandBlockReason ??
                      'O catálogo completo dos 44 serviços da Elytron, '
                          'contratados ou não.',
                  disabled: demandBlockReason != null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubChoiceContent extends StatelessWidget {
  const _HubChoiceContent({
    required this.icon,
    required this.title,
    required this.description,
    this.disabled = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = disabled ? scheme.onSurfaceVariant : scheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (!disabled)
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
      ],
    );
  }
}
