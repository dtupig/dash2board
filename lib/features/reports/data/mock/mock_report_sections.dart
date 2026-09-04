import '../../../auth/domain/user_role.dart';
import '../../domain/models/defense_report.dart';
import '../../domain/models/incident_response_report.dart';
import '../../domain/models/pentest_finding.dart';
import '../../domain/models/pentest_report.dart';
import '../../domain/report.dart';
import '../../domain/report_classification.dart';
import '../../domain/report_section.dart';

/// Deriva as seções de um relatório a partir dos campos do modelo -
/// evita escrever `ReportSection` uma a uma para cada um dos relatórios
/// de demonstração.
List<ReportSection> buildMockSections(ServiceReport report) {
  final List<ReportSection> sections = <ReportSection>[
    ReportSection(
      key: 'resumo',
      title: 'Resumo executivo',
      minimumRole: UserRole.board,
      sensitivity: SectionSensitivity.narrative,
      body: report.executiveSummary,
    ),
    ReportSection(
      key: 'impacto',
      title: 'Impacto no negócio',
      minimumRole: UserRole.board,
      sensitivity: SectionSensitivity.narrative,
      body: report.businessImpact,
    ),
  ];

  if (report is PentestReport) {
    sections.add(ReportSection(
      key: 'metodologia',
      title: 'Metodologia e escopo',
      minimumRole: UserRole.operational,
      sensitivity: SectionSensitivity.technical,
      body: '${report.methodology.join(', ')}. Escopo: ${report.scopeCovered}',
    ));
    for (int i = 0; i < report.findings.length; i++) {
      final PentestFinding f = report.findings[i];
      sections.add(ReportSection(
        key: 'achado-$i',
        title: f.title,
        minimumRole: UserRole.operational,
        sensitivity: f.containsPersonalData
            ? SectionSensitivity.personalData
            : SectionSensitivity.exploitProof,
        body: 'Severidade: ${f.severity.label}. ${f.reproductionSteps} '
            'Remediação: ${f.remediation}',
      ));
    }
  }

  if (report is IncidentResponseReport) {
    sections.add(ReportSection(
      key: 'linha-tempo',
      title: 'Linha do tempo e indicadores',
      minimumRole: UserRole.operational,
      sensitivity: SectionSensitivity.technical,
      body: 'Vetor inicial: ${report.initialVector}. IOCs: '
          '${report.iocs.join(', ')}',
    ));
    if (report.chainOfCustody != null || report.acquisitionHash != null) {
      sections.add(ReportSection(
        key: 'custodia',
        title: 'Cadeia de custódia',
        minimumRole: UserRole.strategic,
        sensitivity: SectionSensitivity.chainOfCustody,
        body: report.chainOfCustody ??
            'Método: ${report.acquisitionMethod ?? '-'}. Hash: '
                '${report.acquisitionHash ?? '-'}. Custodiante: '
                '${report.custodianName ?? '-'}.',
      ));
    }
    if (report.affectedDataSubjects.isNotEmpty) {
      sections.add(ReportSection(
        key: 'dados-pessoais',
        title: 'Titulares de dados afetados',
        minimumRole: UserRole.strategic,
        sensitivity: SectionSensitivity.personalData,
        body: '${report.affectedDataSubjects.length} titular(es) afetado(s).',
      ));
    }
  }

  if (report is DefenseReport && report.credentialsFoundInLeaks.isNotEmpty) {
    sections.add(ReportSection(
      key: 'credenciais',
      title: 'Credenciais encontradas em vazamento',
      minimumRole: UserRole.strategic,
      sensitivity: SectionSensitivity.personalData,
      body: '${report.credentialsFoundInLeaks.length} credencial(is) '
          'encontrada(s) em fontes públicas/dark web.',
    ));
  }

  sections.add(ReportSection(
    key: 'proximos-passos',
    title: 'Próximos passos',
    minimumRole: UserRole.operational,
    sensitivity: SectionSensitivity.technical,
    body: report.nextSteps.isEmpty
        ? 'Sem ações pendentes registradas.'
        : report.nextSteps.map((a) => '${a.title} (${a.ownerName})').join('; '),
  ));

  return sections;
}

/// `secret` exige o registro de leitura antes de renderizar - usado pelo
/// visualizador para decidir se mostra o aviso antes do conteúdo.
bool mockRequiresReceiptGate(ServiceReport report) =>
    report.classification == ReportClassification.secret;
