import '../action_item.dart';
import '../delivery_kind.dart';
import '../material_fact.dart';
import '../report.dart';
import '../report_attachment.dart';
import '../report_classification.dart';

/// Relatório de gestão contínua de vulnerabilidades - distinto de
/// `PentestReport`: aqui o dado é backlog e tendência, não exploração
/// pontual (D-27: nenhum dos 6 relatórios reais de "vulnerabilidades"
/// examinados era, na prática, este modelo - todos eram pentests).
class VulnManagementReport extends ServiceReport {
  const VulnManagementReport({
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
    required this.openBySeverity,
    required this.slaCompliance,
    required this.meanTimeToRemediate,
    required this.backlogTrend,
    required this.activelyExploitedOpen,
    required this.topOffendingAssets,
  });

  final Map<String, int> openBySeverity;

  /// % de achados remediados dentro do SLA contratual.
  final double slaCompliance;
  final double meanTimeToRemediate;
  final List<int> backlogTrend;

  /// Achados com exploração ativa conhecida (KEV/EPSS alto) ainda abertos.
  final int activelyExploitedOpen;
  final List<String> topOffendingAssets;

  factory VulnManagementReport.fromMap(String id, Map<String, Object?> map) {
    return VulnManagementReport(
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
      openBySeverity: (map['openBySeverity'] as Map<String, Object?>?)?.map(
            (String k, Object? v) =>
                MapEntry<String, int>(k, (v as num).toInt()),
          ) ??
          const <String, int>{},
      slaCompliance: (map['slaCompliance'] as num?)?.toDouble() ?? 0,
      meanTimeToRemediate:
          (map['meanTimeToRemediate'] as num?)?.toDouble() ?? 0,
      backlogTrend: (map['backlogTrend'] as List<dynamic>?)
              ?.map((Object? e) => (e as num).toInt())
              .toList(growable: false) ??
          const <int>[],
      activelyExploitedOpen:
          (map['activelyExploitedOpen'] as num?)?.toInt() ?? 0,
      topOffendingAssets: (map['topOffendingAssets'] as List<dynamic>?)
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
        'openBySeverity': openBySeverity,
        'slaCompliance': slaCompliance,
        'meanTimeToRemediate': meanTimeToRemediate,
        'backlogTrend': backlogTrend,
        'activelyExploitedOpen': activelyExploitedOpen,
        'topOffendingAssets': topOffendingAssets,
      };
}
