import '../action_item.dart';
import '../delivery_kind.dart';
import '../material_fact.dart';
import '../report.dart';
import '../report_attachment.dart';
import '../report_classification.dart';

/// Relatório de superfície de ataque - reconhecimento externo contínuo.
class AttackSurfaceReport extends ServiceReport {
  const AttackSurfaceReport({
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
    required this.assetsDiscovered,
    required this.newExposures,
    required this.closedExposures,
    required this.shadowItFound,
    required this.certificateIssues,
    required this.exposedServices,
    required this.changeTimeline,
  });

  final List<String> assetsDiscovered;
  final List<String> newExposures;
  final List<String> closedExposures;
  final List<String> shadowItFound;
  final List<String> certificateIssues;
  final List<String> exposedServices;
  final List<String> changeTimeline;

  factory AttackSurfaceReport.fromMap(String id, Map<String, Object?> map) {
    List<String> stringList(String key) =>
        (map[key] as List<dynamic>?)
            ?.map((Object? e) => e as String)
            .toList(growable: false) ??
        const <String>[];

    return AttackSurfaceReport(
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
      assetsDiscovered: stringList('assetsDiscovered'),
      newExposures: stringList('newExposures'),
      closedExposures: stringList('closedExposures'),
      shadowItFound: stringList('shadowItFound'),
      certificateIssues: stringList('certificateIssues'),
      exposedServices: stringList('exposedServices'),
      changeTimeline: stringList('changeTimeline'),
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
        'assetsDiscovered': assetsDiscovered,
        'newExposures': newExposures,
        'closedExposures': closedExposures,
        'shadowItFound': shadowItFound,
        'certificateIssues': certificateIssues,
        'exposedServices': exposedServices,
        'changeTimeline': changeTimeline,
      };
}
