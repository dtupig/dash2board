import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/surface_card.dart';
import '../../services/data/services_providers.dart';
import '../../services/domain/contracted_service.dart';
import '../data/reports_providers.dart';
import '../domain/report.dart';
import 'reports_formatting.dart';
import 'widgets/classification_badge.dart';

/// Lista de relatórios - `/relatorios`, agrupada por serviço contratado.
/// Relatório só existe para serviço contratado (decisão do prompt 10/11):
/// esta tela cruza os relatórios visíveis com o que o tenant contratou e
/// nunca mostra um relatório de serviço não contratado.
class ReportsListScreen extends ConsumerWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ServiceReport>> reportsAsync =
        ref.watch(reportsProvider);
    final AsyncValue<List<ContractedService>> contractedAsync =
        ref.watch(contractedServicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => const Center(
            child: Text('Não foi possível carregar os relatórios.')),
        data: (List<ServiceReport> reports) {
          final Set<String> contractedKeys = contractedAsync.value
                  ?.map((ContractedService c) => c.serviceKey)
                  .toSet() ??
              <String>{};
          final List<ServiceReport> visible = reports
              .where((ServiceReport r) => contractedKeys.contains(r.serviceKey))
              .toList(growable: false)
            ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));

          if (visible.isEmpty) {
            return const Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Text(
                  'Nenhum relatório disponível ainda para os serviços '
                  'contratados.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) {
              final ServiceReport report = visible[index];
              return SurfaceCard(
                onTap: () => context.push('/relatorios/${report.id}'),
                accent: report.hasMaterialFact
                    ? Theme.of(context).colorScheme.error
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            report.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        ClassificationBadge(
                            classification: report.classification),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${report.referencePeriod} · '
                      '${formatReportDatePtBr(report.deliveredAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    if (report.hasMaterialFact) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Fato relevante',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
