import '../../domain/models/appsec_report.dart';
import '../../domain/models/attack_surface_report.dart';
import '../../domain/models/governance_report.dart';
import '../../domain/models/third_party_report.dart';
import '../../domain/report_classification.dart';

/// Relatórios de demonstração sem fato relevante - AppSec, superfície de
/// ataque, governança e risco de terceiros.
AppSecReport mockAppSecReport(DateTime anchor) {
  return AppSecReport(
    id: 'rep-appsec-001',
    tenantId: 'tenant-demo',
    serviceKey: 'sast',
    category: 'appsec',
    title: 'Programa de AppSec — Relatório Trimestral',
    referencePeriod: '1º trimestre de 2026',
    deliveredAt: anchor.subtract(const Duration(days: 15)),
    version: '1.0',
    elytronLeadName: 'Bruno Kanashiro',
    classification: ReportClassification.restricted,
    executiveSummary:
        'A cobertura de checagem automatizada no pipeline subiu para 82%. '
        'A dívida de segurança em aberto vem caindo há três meses '
        'consecutivos.',
    businessImpact:
        'Redução de retrabalho de correção pós-produção ao detectar '
        'falhas ainda no pipeline.',
    pipelineCoverage: 0.82,
    findingsByStage: const <String, int>{'sast': 40, 'dast': 12, 'manual': 3},
    securityDebtTrend: const <int>[80, 65, 52],
    falsePositiveRate: 0.11,
    trainedDevelopers: 34,
    championsActive: 6,
    policyAdoption: 0.75,
  );
}

AttackSurfaceReport mockAttackSurfaceReport(DateTime anchor) {
  return AttackSurfaceReport(
    id: 'rep-surface-001',
    tenantId: 'tenant-demo',
    serviceKey: 'asm_monitoring',
    category: 'attack_surface',
    title: 'Gestão de Superfície de Ataque — Mensal',
    referencePeriod: 'Fevereiro de 2026',
    deliveredAt: anchor.subtract(const Duration(days: 7)),
    version: '1.0',
    elytronLeadName: 'Bruno Kanashiro',
    classification: ReportClassification.restricted,
    executiveSummary:
        'Nenhuma exposição nova crítica no período. Dois certificados '
        'expiram em 30 dias e já estão sinalizados para renovação.',
    businessImpact: 'Superfície externa estável em relação ao mês anterior.',
    assetsDiscovered: const <String>['app.exemplo.com', 'api.exemplo.com'],
    newExposures: const <String>[],
    closedExposures: const <String>['porta 8080 exposta em servidor legado'],
    shadowItFound: const <String>['ferramenta de formulário não homologada'],
    certificateIssues: const <String>['cert. de staging expira em 30 dias'],
    exposedServices: const <String>['HTTPS', 'SSH restrito por IP'],
    changeTimeline: const <String>['Fechamento da porta 8080 em 10/02/2026'],
  );
}

GovernanceReport mockGovernanceReport(DateTime anchor) {
  return GovernanceReport(
    id: 'rep-governance-001',
    tenantId: 'tenant-demo',
    serviceKey: 'maturity_assessment',
    category: 'governance',
    title: 'Avaliação de Maturidade — ISO 27001',
    referencePeriod: '2025',
    deliveredAt: anchor.subtract(const Duration(days: 60)),
    version: '1.0',
    elytronLeadName: 'Fernanda Prado',
    classification: ReportClassification.restricted,
    executiveSummary:
        'Maturidade média subiu de 2.4 para 3.1 em um ano. Gestão de '
        'acesso e resposta a incidentes seguem como domínios prioritários.',
    businessImpact:
        'Roadmap de 18 meses estimado para certificação, dentro do orçamento '
        'aprovado.',
    framework: 'ISO 27001',
    maturityByDomain: const <String, double>{
      'Gestão de acesso': 2.8,
      'Resposta a incidentes': 2.5,
      'Continuidade de negócio': 3.6,
    },
    targetMaturity: 4,
    gaps: const <String>['Política de resposta a incidentes desatualizada'],
    roadmapPhases: const <String>[
      'Fase 1: políticas',
      'Fase 2: controles técnicos'
    ],
    estimatedInvestment: 180000,
  );
}

ThirdPartyReport mockThirdPartyReport(DateTime anchor) {
  return ThirdPartyReport(
    id: 'rep-thirdparty-001',
    tenantId: 'tenant-demo',
    serviceKey: 'third_party_management',
    category: 'third_party',
    title: 'Avaliação de Risco de Fornecedores',
    referencePeriod: '2025',
    deliveredAt: anchor.subtract(const Duration(days: 45)),
    version: '1.0',
    elytronLeadName: 'Fernanda Prado',
    classification: ReportClassification.restricted,
    executiveSummary:
        '14 fornecedores avaliados; nenhum em nível de risco crítico sem '
        'plano de tratamento.',
    businessImpact: 'Concentração de risco baixa - nenhum fornecedor único '
        'concentra mais de 20% da exposição avaliada.',
    suppliersAssessed: 14,
    riskTierDistribution: const <String, int>{
      'alto': 2,
      'médio': 5,
      'baixo': 7
    },
    criticalSuppliers: const <String>[],
    contractClauseGaps: const <String>[
      'Cláusula de notificação de incidente ausente em 3 contratos'
    ],
    concentrationRisk: 'Baixo.',
    fourthPartyExposure: const <String>[
      'Provedor de nuvem do fornecedor principal'
    ],
  );
}
