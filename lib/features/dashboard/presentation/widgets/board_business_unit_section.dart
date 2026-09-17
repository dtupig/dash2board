import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/charts/chart_frame.dart';
import '../../../../core/widgets/charts/domain_bar_chart.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../strategic/domain/risk_item.dart';
import '../../../strategic/domain/tenant_profile.dart';
import '../../../strategic/presentation/briefing_formatting.dart';

/// Bloco 2 do painel do board: impacto por unidade de negócio, com o nome
/// do executivo responsável ao lado de cada uma - "risco sem dono nomeado
/// não gera decisão". Toque numa unidade (barra ou linha da lista) abre os
/// riscos por trás do número. Extraído de `board_dashboard_screen.dart`
/// (Bucket B) ao dar a HU-W-14 seu layout de tela larga.
class BoardBusinessUnitSection extends StatelessWidget {
  const BoardBusinessUnitSection({
    super.key,
    required this.risks,
    required this.profile,
    required this.aleByBusinessUnit,
  });

  final List<RiskItem> risks;
  final TenantProfile profile;
  final Map<String, double> aleByBusinessUnit;

  double get _maxAle => aleByBusinessUnit.values.isEmpty
      ? 1
      : aleByBusinessUnit.values.reduce((double a, double b) => a > b ? a : b);

  void _openBusinessUnitSheet(BuildContext context, String businessUnit) {
    final List<RiskItem> unitRisks = risks
        .where((RiskItem r) => r.businessUnit == businessUnit)
        .toList(growable: false)
      ..sort((RiskItem a, RiskItem b) =>
          b.annualLossExpectancy.compareTo(a.annualLossExpectancy));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => _BusinessUnitRisksSheet(
        businessUnit: businessUnit,
        ownerName: profile.ownerFor(businessUnit),
        risks: unitRisks,
      ),
    );
  }

  Widget _businessUnitTable(BuildContext context) {
    final List<MapEntry<String, double>> sorted = aleByBusinessUnit.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SizedBox(
      height: 280,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          for (final MapEntry<String, double> entry in sorted)
            ListTile(
              title: Text(entry.key),
              subtitle: Text(profile.ownerFor(entry.key)),
              trailing: Text(formatCurrencyBrl(entry.value)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChartFrame(
          title: 'Impacto por unidade de negócio',
          subtitle:
              'Toque em uma unidade para ver os riscos por trás do número.',
          height: 76.0 * aleByBusinessUnit.length + 24,
          onShowTable: _businessUnitTable,
          child: DomainBarChart(
            data: <DomainBarDatum>[
              for (final MapEntry<String, double> entry
                  in aleByBusinessUnit.entries)
                DomainBarDatum(label: entry.key, value: entry.value),
            ],
            maxValue: _maxAle,
            valueLabelBuilder: formatCurrencyCompactBrl,
            valueColumnWidth: 68,
            onSelect: (String bu) => _openBusinessUnitSheet(context, bu),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // "Ao lado de cada unidade, o nome do executivo responsável" - a
        // barra acima já não tem espaço para o nome completo do executivo,
        // então a lista abaixo faz o pareamento explícito unidade -> dono.
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final String bu in aleByBusinessUnit.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '$bu — ${profile.ownerFor(bu)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BusinessUnitRisksSheet extends StatelessWidget {
  const _BusinessUnitRisksSheet({
    required this.businessUnit,
    required this.ownerName,
    required this.risks,
  });

  final String businessUnit;
  final String ownerName;
  final List<RiskItem> risks;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController scrollController) {
        return SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  businessUnit,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                'Executivo responsável: $ownerName',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (risks.isEmpty)
                const ChartEmpty(
                  message: 'Nenhum risco aberto nesta unidade agora.',
                )
              else
                for (final RiskItem risk in risks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _RiskSummaryCard(risk: risk),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _RiskSummaryCard extends StatelessWidget {
  const _RiskSummaryCard({required this.risk});

  final RiskItem risk;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            risk.title,
            style:
                theme.textTheme.titleSmall?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Quanto custaria: ${formatCurrencyBrl(risk.annualLossExpectancy)} por ano, '
            'em média, se acontecer.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'O que está sendo feito: ${risk.treatment.label} · situação: '
            '${risk.acceptance.label}.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
