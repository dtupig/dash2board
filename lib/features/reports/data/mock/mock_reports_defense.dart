import '../../domain/material_fact.dart';
import '../../domain/models/defense_report.dart';
import '../../domain/report_classification.dart';

/// Relatório de defesa/CTI de demonstração - padrão "CEEC Threat
/// Intelligence Report" (anonimizado, D-27): credencial corporativa achada
/// em vazamento dispara `leakedCorporateCredentials` e
/// `personalDataExposure` ao mesmo tempo.
List<DefenseReport> mockDefenseReports(DateTime anchor) {
  return <DefenseReport>[
    DefenseReport(
      id: 'rep-defense-001',
      tenantId: 'tenant-demo',
      serviceKey: 'threat_intelligence',
      category: 'defense',
      title: 'Inteligência de Ameaças — Monitoramento Contínuo',
      referencePeriod: 'Fevereiro de 2026',
      deliveredAt: anchor.subtract(const Duration(days: 10)),
      version: '3.0',
      elytronLeadName: 'Marina Fontoura',
      clientContactName: 'Patrícia Lemos',
      classification: ReportClassification.confidential,
      executiveSummary:
          'O monitoramento identificou 3 credenciais corporativas válidas '
          'em vazamentos públicos, associadas a um ecossistema de '
          'fornecedor terceiro. Recomenda-se troca imediata de senha e '
          'ativação de autenticação multifator.',
      businessImpact:
          'Uma credencial válida em mãos erradas pode virar acesso não '
          'autorizado a sistema interno - ação de troca de senha não pode '
          'esperar o próximo ciclo.',
      materialFacts: <MaterialFact>[
        MaterialFact(
          trigger: MaterialFactTrigger.leakedCorporateCredentials,
          title: 'Credencial corporativa encontrada em vazamento',
          consequence:
              'Uma credencial válida em mãos erradas vira porta de entrada '
              'para o ambiente interno.',
          detectedAt: anchor.subtract(const Duration(days: 10)),
          decisionRequired: true,
        ),
        MaterialFact(
          trigger: MaterialFactTrigger.personalDataExposure,
          title: 'Dado pessoal associado à credencial vazada',
          consequence:
              'Pode gerar obrigação de notificação e sanção regulatória.',
          detectedAt: anchor.subtract(const Duration(days: 10)),
          decisionRequired: false,
        ),
      ],
      controlCoverage: 0.72,
      detectionsByTactic: const <String, int>{
        'Credential Access': 4,
        'Initial Access': 1,
      },
      tuningActions: const <String>[
        'Ajustar regra de alerta para login fora do horário comercial.',
      ],
      falsePositiveReduction: 0.18,
      phishingClickRate: 0.04,
      credentialsFoundInLeaks: const <String>[
        'usuario.corporativo@cliente-demo.com',
        'admin.homolog@cliente-demo.com',
        'suporte.ti@cliente-demo.com',
      ],
      hardeningRecommendations: const <String>[
        'Forçar MFA em toda conta administrativa.',
        'Rotacionar senha de todas as credenciais expostas em até 24h.',
      ],
      relatedSurfaceFindings: const <String>[
        'Subdomínio de homologação de fornecedor terceiro com painel '
            'administrativo exposto.',
      ],
    ),
  ];
}
