import 'material_fact.dart';
import 'models/defense_report.dart';
import 'models/governance_report.dart';
import 'models/incident_response_report.dart';
import 'models/pentest_finding.dart';
import 'models/pentest_report.dart';
import 'models/third_party_report.dart';
import 'report.dart';

/// Avalia um relatório contra os 8 gatilhos fechados de fato relevante.
///
/// **Pura e determinística**: mesmo relatório, mesmo resultado, sempre.
/// Cada gatilho lê um campo explícito do modelo - nada de heurística
/// implícita ou parsing de texto livre. Um relatório pode disparar mais de
/// um gatilho ao mesmo tempo (validado contra caso real de D-27: um único
/// achado de pentest com dado pessoal e indício de abuso dispara
/// `personalDataExposure`, `criticalInternetFacing` e
/// `confirmedCompromise` simultaneamente).
abstract final class MaterialFactEvaluator {
  static const int regulatoryDeadlineWindowDays = 90;

  /// [tenantRevenueThreshold] é o limite de exposição financeira do tenant
  /// (25% da receita, por tenant - D-29). Ainda não há campo de receita do
  /// tenant no modelo de dados atual (chega no prompt 14); até lá, quem
  /// chama decide o valor (o mock usa uma constante) e, sem valor, o
  /// gatilho `financialExposureThreshold` simplesmente não dispara.
  static List<MaterialFact> evaluate(
    ServiceReport report, {
    double? tenantRevenueThreshold,
    required DateTime now,
  }) {
    final List<MaterialFact> facts = <MaterialFact>[];

    void add(
      MaterialFactTrigger trigger,
      String title,
      String consequence, {
      double? estimatedExposure,
      bool decisionRequired = true,
    }) {
      facts.add(MaterialFact(
        trigger: trigger,
        title: title,
        consequence: consequence,
        detectedAt: report.deliveredAt,
        estimatedExposure: estimatedExposure,
        decisionRequired: decisionRequired,
      ));
    }

    if (report is IncidentResponseReport) {
      if (report.iocs.isNotEmpty) {
        add(
          MaterialFactTrigger.confirmedCompromise,
          'Comprometimento confirmado com indício técnico',
          'Sem contenção completa, o atacante mantém acesso ao ambiente.',
        );
      }
      if (report.affectedDataSubjects.isNotEmpty ||
          report.regulatoryNotificationRequired) {
        add(
          MaterialFactTrigger.personalDataExposure,
          'Dado pessoal exposto no incidente',
          'Pode gerar obrigação de notificação e sanção regulatória.',
        );
      }
      if (report.businessContinuityThreatened) {
        add(
          MaterialFactTrigger.businessContinuityRisk,
          'Processo crítico de negócio ameaçado',
          'Interrupção prolongada afeta a operação do cliente.',
        );
      }
    }

    if (report is PentestReport) {
      final bool hasCriticalFinding = report.findings.any(
        (PentestFinding f) => f.severity.wireValue == 'critical',
      );
      if (hasCriticalFinding) {
        add(
          MaterialFactTrigger.criticalInternetFacing,
          'Achado crítico em ativo exposto',
          'Um atacante pode explorar a falha sem acesso privilegiado prévio.',
        );
      }
      final bool hasPersonalData =
          report.findings.any((PentestFinding f) => f.containsPersonalData);
      if (hasPersonalData) {
        add(
          MaterialFactTrigger.personalDataExposure,
          'Dado pessoal exposto no teste',
          'Pode gerar obrigação de notificação e sanção regulatória.',
        );
      }
      final bool hasActiveAbuse =
          report.findings.any((PentestFinding f) => f.indicatesActiveAbuse);
      if (hasActiveAbuse) {
        add(
          MaterialFactTrigger.confirmedCompromise,
          'Indício de exploração ativa por terceiro',
          'Há sinal técnico de uso indevido não autorizado, mesmo sem '
              'confirmação formal - aguardar confirmação atrasa a resposta.',
        );
      }
    }

    if (report is GovernanceReport) {
      final bool hasNearDeadline = report.regulatoryDeadlines.any(
        (DateTime d) =>
            !d.isBefore(now) &&
            d.difference(now).inDays <= regulatoryDeadlineWindowDays,
      );
      if (hasNearDeadline) {
        add(
          MaterialFactTrigger.regulatoryDeadlineRisk,
          'Prazo regulatório em risco',
          'Perder o prazo pode gerar multa ou restrição operacional.',
        );
      }
    }

    if (report is ThirdPartyReport && report.criticalSuppliers.isNotEmpty) {
      add(
        MaterialFactTrigger.criticalSupplierRisk,
        'Fornecedor crítico com risco não tratado',
        'Uma falha do fornecedor pode interromper a operação do cliente.',
      );
    }

    if (report is DefenseReport && report.credentialsFoundInLeaks.isNotEmpty) {
      add(
        MaterialFactTrigger.leakedCorporateCredentials,
        'Credencial corporativa encontrada em vazamento',
        'Uma credencial válida em mãos erradas vira porta de entrada.',
      );
      add(
        MaterialFactTrigger.personalDataExposure,
        'Dado pessoal exposto em vazamento de credenciais',
        'Pode gerar obrigação de notificação e sanção regulatória.',
      );
    }

    if (tenantRevenueThreshold != null &&
        report.estimatedExposureValue != null &&
        report.estimatedExposureValue! >= tenantRevenueThreshold) {
      add(
        MaterialFactTrigger.financialExposureThreshold,
        'Exposição financeira acima do limite do tenant',
        'O valor em risco supera o limite que o board definiu para decisão '
            'automática.',
        estimatedExposure: report.estimatedExposureValue,
      );
    }

    return facts;
  }
}
