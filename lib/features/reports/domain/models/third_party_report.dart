import '../action_item.dart';
import '../delivery_kind.dart';
import '../material_fact.dart';
import '../report.dart';
import '../report_attachment.dart';
import '../report_classification.dart';

/// Relatório de risco de terceiros (fornecedores).
class ThirdPartyReport extends ServiceReport {
  const ThirdPartyReport({
    required super.id,
    required super.tenantId,
    required super.serviceKey,
    required super.category,
    required super.title,
    required super.referencePeriod,
    required super.deliveredAt,
    required super.version,
    required super.elytronLeadName,
    super.clientContactName,
    required super.classification,
    super.deliveryKind,
    required super.executiveSummary,
    required super.businessImpact,
    super.estimatedExposureValue,
    super.materialFacts,
    super.nextSteps,
    super.attachments,
    required this.suppliersAssessed,
    required this.riskTierDistribution,
    required this.criticalSuppliers,
    required this.contractClauseGaps,
    required this.concentrationRisk,
    required this.fourthPartyExposure,
  });

  final int suppliersAssessed;

  /// Distribuição por nível de risco (ex.: `{"alto": 3, "médio": 8}`).
  final Map<String, int> riskTierDistribution;

  /// Fornecedores críticos com risco não tratado - alimenta o gatilho
  /// `criticalSupplierRisk`.
  final List<String> criticalSuppliers;
  final List<String> contractClauseGaps;

  /// Risco de concentração (poucos fornecedores concentrando exposição).
  final String concentrationRisk;

  /// Exposição via fornecedor do fornecedor (quarta parte).
  final List<String> fourthPartyExposure;

  factory ThirdPartyReport.fromMap(String id, Map<String, Object?> map) {
    return ThirdPartyReport(
      id: id,
      tenantId: map['tenantId'] as String? ?? '',
      serviceKey: map['serviceKey'] as String? ?? '',
      category: map['category'] as String? ?? '',
      title: map['title'] as String? ?? '',
      referencePeriod: map['referencePeriod'] as String? ?? '',
      deliveredAt: map['deliveredAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      version: map['version'] as String? ?? '',
      elytronLeadName: map['elytronLeadName'] as String? ?? '',
      clientContactName: map['clientContactName'] as String?,
      classification: ReportClassification.fromWire(map['classification']),
      deliveryKind: DeliveryKind.fromWire(map['deliveryKind']),
      executiveSummary: map['executiveSummary'] as String? ?? '',
      businessImpact: map['businessImpact'] as String? ?? '',
      estimatedExposureValue:
          (map['estimatedExposureValue'] as num?)?.toDouble(),
      materialFacts: (map['materialFacts'] as List<dynamic>?)
              ?.map((Object? e) =>
                  MaterialFact.fromMap(e as Map<String, Object?>))
              .toList(growable: false) ??
          const <MaterialFact>[],
      nextSteps: (map['nextSteps'] as List<dynamic>?)
              ?.map(
                  (Object? e) => ActionItem.fromMap(e as Map<String, Object?>))
              .toList(growable: false) ??
          const <ActionItem>[],
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((Object? e) =>
                  ReportAttachment.fromMap(e as Map<String, Object?>))
              .toList(growable: false) ??
          const <ReportAttachment>[],
      suppliersAssessed: (map['suppliersAssessed'] as num?)?.toInt() ?? 0,
      riskTierDistribution:
          (map['riskTierDistribution'] as Map<String, Object?>?)?.map(
                (String k, Object? v) =>
                    MapEntry<String, int>(k, (v as num).toInt()),
              ) ??
              const <String, int>{},
      criticalSuppliers: (map['criticalSuppliers'] as List<dynamic>?)
              ?.map((Object? e) => e as String)
              .toList(growable: false) ??
          const <String>[],
      contractClauseGaps: (map['contractClauseGaps'] as List<dynamic>?)
              ?.map((Object? e) => e as String)
              .toList(growable: false) ??
          const <String>[],
      concentrationRisk: map['concentrationRisk'] as String? ?? '',
      fourthPartyExposure: (map['fourthPartyExposure'] as List<dynamic>?)
              ?.map((Object? e) => e as String)
              .toList(growable: false) ??
          const <String>[],
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'tenantId': tenantId,
        'serviceKey': serviceKey,
        'category': category,
        'title': title,
        'referencePeriod': referencePeriod,
        'deliveredAt': deliveredAt,
        'version': version,
        'elytronLeadName': elytronLeadName,
        'clientContactName': clientContactName,
        'classification': classification.wireValue,
        'deliveryKind': deliveryKind.wireValue,
        'executiveSummary': executiveSummary,
        'businessImpact': businessImpact,
        'estimatedExposureValue': estimatedExposureValue,
        'materialFacts': <Map<String, Object?>>[
          for (final MaterialFact f in materialFacts) f.toMap(),
        ],
        'nextSteps': <Map<String, Object?>>[
          for (final ActionItem a in nextSteps) a.toMap(),
        ],
        'attachments': <Map<String, Object?>>[
          for (final ReportAttachment a in attachments) a.toMap(),
        ],
        'suppliersAssessed': suppliersAssessed,
        'riskTierDistribution': riskTierDistribution,
        'criticalSuppliers': criticalSuppliers,
        'contractClauseGaps': contractClauseGaps,
        'concentrationRisk': concentrationRisk,
        'fourthPartyExposure': fourthPartyExposure,
      };
}
