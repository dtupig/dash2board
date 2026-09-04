import '../../domain/models/vuln_management_report.dart';
import '../../domain/report_classification.dart';

/// Duas entregas do mesmo serviço de gestão de vulnerabilidades - exercita
/// a comparação com a entrega anterior (critério de aceite do prompt 11).
List<VulnManagementReport> mockVulnManagementReports(DateTime anchor) {
  return <VulnManagementReport>[
    VulnManagementReport(
      id: 'rep-vuln-001',
      tenantId: 'tenant-demo',
      serviceKey: 'vulnerability_management',
      category: 'vulnerability',
      title: 'Gestão de Vulnerabilidades — Ciclo Anterior',
      referencePeriod: '4º trimestre de 2025',
      deliveredAt: anchor.subtract(const Duration(days: 95)),
      version: '1.0',
      elytronLeadName: 'Igor Cavalcanti',
      classification: ReportClassification.restricted,
      executiveSummary:
          'Backlog de vulnerabilidades em queda; SLA de correção cumprido '
          'em 78% dos casos.',
      businessImpact: 'Redução do tempo médio de exposição de ativos '
          'críticos.',
      openBySeverity: const <String, int>{'crítico': 1, 'alto': 6, 'médio': 22},
      slaCompliance: 0.78,
      meanTimeToRemediate: 21,
      backlogTrend: const <int>[40, 35, 29],
      activelyExploitedOpen: 1,
      topOffendingAssets: const <String>['servidor-legado-01'],
    ),
    VulnManagementReport(
      id: 'rep-vuln-002',
      tenantId: 'tenant-demo',
      serviceKey: 'vulnerability_management',
      category: 'vulnerability',
      title: 'Gestão de Vulnerabilidades — Ciclo Atual',
      referencePeriod: '1º trimestre de 2026',
      deliveredAt: anchor.subtract(const Duration(days: 5)),
      version: '2.0',
      elytronLeadName: 'Igor Cavalcanti',
      classification: ReportClassification.restricted,
      executiveSummary:
          'SLA de correção subiu para 85% em relação ao ciclo anterior '
          '(78%). Nenhum achado com exploração ativa permanece em aberto.',
      businessImpact:
          'Tendência de melhora sustentada - backlog caiu 25% no trimestre.',
      openBySeverity: const <String, int>{'crítico': 0, 'alto': 4, 'médio': 18},
      slaCompliance: 0.85,
      meanTimeToRemediate: 16,
      backlogTrend: const <int>[29, 24, 22],
      activelyExploitedOpen: 0,
      topOffendingAssets: const <String>['servidor-legado-01'],
    ),
  ];
}
