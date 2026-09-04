import 'action_item.dart';
import 'delivery_kind.dart';
import 'material_fact.dart';
import 'report_attachment.dart';
import 'report_classification.dart';

/// Base comum a todo relatório de serviço - os 8 modelos especialistas
/// estendem este e acrescentam o que a disciplina realmente entrega.
///
/// Espelha `/tenants/{tenantId}/reports/{reportId}`, com a subcoleção
/// `sections` guardando o conteúdo por seção (`ReportSection`).
class ServiceReport {
  const ServiceReport({
    required this.id,
    required this.tenantId,
    required this.serviceKey,
    required this.category,
    required this.title,
    required this.referencePeriod,
    required this.deliveredAt,
    required this.version,
    required this.elytronLeadName,
    this.clientContactName,
    required this.classification,
    this.deliveryKind = DeliveryKind.scheduled,
    required this.executiveSummary,
    required this.businessImpact,
    this.estimatedExposureValue,
    this.materialFacts = const <MaterialFact>[],
    this.nextSteps = const <ActionItem>[],
    this.attachments = const <ReportAttachment>[],
  });

  final String id;
  final String tenantId;
  final String serviceKey;

  /// `categoryKey` do catálogo (`docs/08_CATALOGO_SERVICOS.md`).
  final String category;
  final String title;
  final String referencePeriod;
  final DateTime deliveredAt;
  final String version;
  final String elytronLeadName;

  /// Contato do cliente que recebe o relatório - presente em 100% dos
  /// relatórios reais examinados na validação de D-27.
  final String? clientContactName;
  final ReportClassification classification;
  final DeliveryKind deliveryKind;

  /// 3 a 5 frases, linguagem de negócio.
  final String executiveSummary;
  final String businessImpact;

  /// Exposição financeira estimada em Real, quando o relatório sustenta uma
  /// - usada por `MaterialFactEvaluator` para o gatilho
  /// `financialExposureThreshold`.
  final double? estimatedExposureValue;

  final List<MaterialFact> materialFacts;
  final List<ActionItem> nextSteps;
  final List<ReportAttachment> attachments;

  bool get hasMaterialFact => materialFacts.isNotEmpty;

  @override
  bool operator ==(Object other) => other is ServiceReport && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ServiceReport($id, $serviceKey, ${classification.wireValue})';
}
