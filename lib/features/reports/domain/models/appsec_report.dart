import '../action_item.dart';
import '../delivery_kind.dart';
import '../material_fact.dart';
import '../report.dart';
import '../report_attachment.dart';
import '../report_classification.dart';

/// Relatório de segurança de aplicações contínua (AppSec) - cobertura de
/// pipeline, tendência de dívida de segurança, adoção de política.
class AppSecReport extends ServiceReport {
  const AppSecReport({
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
    required this.pipelineCoverage,
    required this.findingsByStage,
    required this.securityDebtTrend,
    required this.falsePositiveRate,
    required this.trainedDevelopers,
    required this.championsActive,
    required this.policyAdoption,
  });

  /// % do pipeline de CI/CD coberto por checagem automatizada.
  final double pipelineCoverage;

  /// Achados por estágio (`sast`, `dast`, `manual`) -> contagem.
  final Map<String, int> findingsByStage;

  /// Série mensal da dívida de segurança em aberto.
  final List<int> securityDebtTrend;
  final double falsePositiveRate;
  final int trainedDevelopers;
  final int championsActive;

  /// % de repositórios aderentes à política de segurança de código.
  final double policyAdoption;

  factory AppSecReport.fromMap(String id, Map<String, Object?> map) {
    return AppSecReport(
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
      pipelineCoverage: (map['pipelineCoverage'] as num?)?.toDouble() ?? 0,
      findingsByStage: (map['findingsByStage'] as Map<String, Object?>?)?.map(
            (String k, Object? v) =>
                MapEntry<String, int>(k, (v as num).toInt()),
          ) ??
          const <String, int>{},
      securityDebtTrend: (map['securityDebtTrend'] as List<dynamic>?)
              ?.map((Object? e) => (e as num).toInt())
              .toList(growable: false) ??
          const <int>[],
      falsePositiveRate: (map['falsePositiveRate'] as num?)?.toDouble() ?? 0,
      trainedDevelopers: (map['trainedDevelopers'] as num?)?.toInt() ?? 0,
      championsActive: (map['championsActive'] as num?)?.toInt() ?? 0,
      policyAdoption: (map['policyAdoption'] as num?)?.toDouble() ?? 0,
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
        'pipelineCoverage': pipelineCoverage,
        'findingsByStage': findingsByStage,
        'securityDebtTrend': securityDebtTrend,
        'falsePositiveRate': falsePositiveRate,
        'trainedDevelopers': trainedDevelopers,
        'championsActive': championsActive,
        'policyAdoption': policyAdoption,
      };
}
