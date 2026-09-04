import '../../domain/models/incident_response_report.dart';
import '../../domain/models/incident_timeline_event.dart';
import '../../domain/report_classification.dart';

/// Relatório de perícia forense de demonstração - `secret`, exercita o
/// registro de leitura. Campos de custódia inspirados nos templates
/// genéricos e sintéticos de `docs/templates/custody_record_generic_
/// device.json` (D-27/D-32) - nunca dado real de cliente.
List<IncidentResponseReport> mockIncidentReports(DateTime anchor) {
  return <IncidentResponseReport>[
    IncidentResponseReport(
      id: 'rep-incident-001',
      tenantId: 'tenant-demo',
      serviceKey: 'digital_investigation',
      category: 'response',
      title: 'Investigação de Fraude Financeira Interna',
      referencePeriod: 'Janeiro de 2026',
      deliveredAt: anchor.subtract(const Duration(days: 30)),
      version: '1.0',
      elytronLeadName: 'Renata Sousa',
      clientContactName: 'Diretor Financeiro (nome reservado)',
      classification: ReportClassification.secret,
      executiveSummary:
          'A investigação confirmou comprometimento de credencial de conta '
          'de serviço em nuvem, usada para acesso não autorizado a sistema '
          'financeiro interno. Contenção concluída; nenhuma evidência de '
          'exfiltração de dado de cliente final.',
      businessImpact:
          'Processo financeiro interno foi isolado por 6 horas durante a '
          'contenção; sem impacto a cliente final.',
      incidentTimeline: <IncidentTimelineEvent>[
        IncidentTimelineEvent(
          occurredAt: anchor.subtract(const Duration(days: 34)),
          description: 'Primeiro acesso não autorizado identificado em log.',
        ),
        IncidentTimelineEvent(
          occurredAt: anchor.subtract(const Duration(days: 33)),
          description: 'Contenção: credencial revogada, acesso bloqueado.',
        ),
      ],
      initialVector: 'Comprometimento de credencial de conta de serviço.',
      dwellTimeHours: 26,
      containmentAt: anchor.subtract(const Duration(days: 33)),
      eradicationAt: anchor.subtract(const Duration(days: 32)),
      iocs: const <String>[
        'IP de origem associado a provedor de hospedagem anônimo.',
        'Criação de conta de serviço não autorizada.',
      ],
      chainOfCustody: 'Imagem forense da VM adquirida bit a bit, hash SHA-256 '
          'registrado no momento da coleta. Ver registro de custódia '
          'genérico em docs/templates/ - dado sintético.',
      regulatoryNotificationRequired: false,
      lessonsLearned:
          'Rotacionar credenciais de conta de serviço periodicamente e '
          'restringir permissão pelo princípio de menor privilégio.',
      forensicStandardsApplied: const <String>[
        'ISO/IEC 27037',
        'NIST SP 800-86',
      ],
      cloudResourceIdentifiers: const <String, String>{
        'provider': 'gcp',
        'projectId': 'projeto-generico-prd',
        'resourceType': 'compute_instance',
        'resourceId': 'instance-generica-000000',
      },
      acquisitionHash:
          '0000000000000000000000000000000000000000000000000000000000dd',
      custodianName: 'Nome do Custodiante',
      acquisitionMethod: 'Snapshot de disco + exportação de logs de auditoria.',
    ),
  ];
}
