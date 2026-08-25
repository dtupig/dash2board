import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../domain/material_fact.dart';
import '../../domain/report.dart';
import 'material_fact_card.dart';
import 'report_header.dart';

/// Visão `board`: sumário executivo, fatos relevantes com consequência e
/// exposição financeira, decisões pendentes. **Nada mais** - sem CVE, sem
/// CVSS, sem nome de ferramenta, sem passo de reprodução. Por isso esta
/// visão NÃO itera `sections` genéricas: ela só renderiza os campos do
/// modelo comum, que já são curados em linguagem de negócio.
class BoardReportView extends StatelessWidget {
  const BoardReportView({super.key, required this.report});

  final ServiceReport report;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.screenPadding,
      children: <Widget>[
        ReportHeader(report: report),
        const SizedBox(height: AppSpacing.lg),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Resumo executivo', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(report.executiveSummary, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Impacto no negócio', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(report.businessImpact, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        if (report.materialFacts.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Text('Decisões pendentes', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final MaterialFact fact in report.materialFacts) ...<Widget>[
            MaterialFactCard(fact: fact),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}
