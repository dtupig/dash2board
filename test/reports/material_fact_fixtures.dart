import 'package:elytron_dash2board/features/reports/domain/finding_severity.dart';
import 'package:elytron_dash2board/features/reports/domain/models/defense_report.dart';
import 'package:elytron_dash2board/features/reports/domain/models/governance_report.dart';
import 'package:elytron_dash2board/features/reports/domain/models/incident_response_report.dart';
import 'package:elytron_dash2board/features/reports/domain/models/incident_timeline_event.dart';
import 'package:elytron_dash2board/features/reports/domain/models/pentest_finding.dart';
import 'package:elytron_dash2board/features/reports/domain/models/pentest_report.dart';
import 'package:elytron_dash2board/features/reports/domain/models/third_party_report.dart';
import 'package:elytron_dash2board/features/reports/domain/report_classification.dart';

/// Fixtures mínimas dos 8 modelos, usadas pelos testes de
/// `MaterialFactEvaluator` - um relatório completo real tem muito mais
/// campo do que o necessário para exercitar um gatilho isolado.
final DateTime now = DateTime.utc(2026, 3, 1);
final DateTime deliveredAt = DateTime.utc(2026, 2, 20);

PentestFinding finding({
  FindingSeverity severity = FindingSeverity.low,
  bool containsPersonalData = false,
  bool indicatesActiveAbuse = false,
}) {
  return PentestFinding(
    title: 'Achado de teste',
    cvssScore: 5,
    severity: severity,
    cweId: 'CWE-000',
    affectedAssets: const <String>['api.exemplo.com'],
    businessConsequence: 'Consequência de negócio.',
    reproductionSteps: 'Passos.',
    remediation: 'Corrigir.',
    containsPersonalData: containsPersonalData,
    indicatesActiveAbuse: indicatesActiveAbuse,
  );
}

PentestReport pentestReport({
  List<PentestFinding> findings = const <PentestFinding>[],
  double? estimatedExposureValue,
}) {
  return PentestReport(
    id: 'r1',
    tenantId: 'tenant-demo',
    serviceKey: 'web_api',
    category: 'pentest',
    title: 'Pentest',
    referencePeriod: 'Q1 2026',
    deliveredAt: deliveredAt,
    version: '1.0',
    elytronLeadName: 'Responsável Elytron',
    classification: ReportClassification.confidential,
    executiveSummary: 'Resumo.',
    businessImpact: 'Impacto.',
    estimatedExposureValue: estimatedExposureValue,
    findings: findings,
    scopeCovered: 'Escopo.',
    methodology: const <String>['PTES'],
  );
}

IncidentResponseReport incidentReport({
  List<String> iocs = const <String>[],
  List<String> affectedDataSubjects = const <String>[],
  bool regulatoryNotificationRequired = false,
  bool businessContinuityThreatened = false,
}) {
  return IncidentResponseReport(
    id: 'r2',
    tenantId: 'tenant-demo',
    serviceKey: 'incident_response',
    category: 'response',
    title: 'Resposta a incidente',
    referencePeriod: 'Q1 2026',
    deliveredAt: deliveredAt,
    version: '1.0',
    elytronLeadName: 'Responsável Elytron',
    classification: ReportClassification.secret,
    executiveSummary: 'Resumo.',
    businessImpact: 'Impacto.',
    incidentTimeline: const <IncidentTimelineEvent>[],
    initialVector: 'Credencial comprometida.',
    iocs: iocs,
    affectedDataSubjects: affectedDataSubjects,
    regulatoryNotificationRequired: regulatoryNotificationRequired,
    lessonsLearned: 'Lições.',
    businessContinuityThreatened: businessContinuityThreatened,
  );
}

GovernanceReport governanceReport({
  List<DateTime> regulatoryDeadlines = const <DateTime>[],
}) {
  return GovernanceReport(
    id: 'r3',
    tenantId: 'tenant-demo',
    serviceKey: 'grc_advisory',
    category: 'governance',
    title: 'Governança',
    referencePeriod: 'Q1 2026',
    deliveredAt: deliveredAt,
    version: '1.0',
    elytronLeadName: 'Responsável Elytron',
    classification: ReportClassification.restricted,
    executiveSummary: 'Resumo.',
    businessImpact: 'Impacto.',
    framework: 'ISO 27001',
    maturityByDomain: const <String, double>{},
    targetMaturity: 4,
    gaps: const <String>[],
    roadmapPhases: const <String>[],
    estimatedInvestment: 0,
    regulatoryDeadlines: regulatoryDeadlines,
  );
}

ThirdPartyReport thirdPartyReport({
  List<String> criticalSuppliers = const <String>[],
}) {
  return ThirdPartyReport(
    id: 'r4',
    tenantId: 'tenant-demo',
    serviceKey: 'third_party_risk',
    category: 'third_party',
    title: 'Risco de terceiros',
    referencePeriod: 'Q1 2026',
    deliveredAt: deliveredAt,
    version: '1.0',
    elytronLeadName: 'Responsável Elytron',
    classification: ReportClassification.restricted,
    executiveSummary: 'Resumo.',
    businessImpact: 'Impacto.',
    suppliersAssessed: 10,
    riskTierDistribution: const <String, int>{},
    criticalSuppliers: criticalSuppliers,
    contractClauseGaps: const <String>[],
    concentrationRisk: 'Baixo.',
    fourthPartyExposure: const <String>[],
  );
}

DefenseReport defenseReport({
  List<String> credentialsFoundInLeaks = const <String>[],
}) {
  return DefenseReport(
    id: 'r5',
    tenantId: 'tenant-demo',
    serviceKey: 'threat_intelligence',
    category: 'defense',
    title: 'Defesa e CTI',
    referencePeriod: 'Q1 2026',
    deliveredAt: deliveredAt,
    version: '1.0',
    elytronLeadName: 'Responsável Elytron',
    classification: ReportClassification.confidential,
    executiveSummary: 'Resumo.',
    businessImpact: 'Impacto.',
    controlCoverage: 0.8,
    detectionsByTactic: const <String, int>{},
    tuningActions: const <String>[],
    falsePositiveReduction: 0,
    phishingClickRate: 0,
    credentialsFoundInLeaks: credentialsFoundInLeaks,
    hardeningRecommendations: const <String>[],
  );
}
