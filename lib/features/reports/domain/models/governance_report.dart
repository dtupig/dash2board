import '../action_item.dart';
import '../delivery_kind.dart';
import '../material_fact.dart';
import '../report.dart';
import '../report_attachment.dart';
import '../report_classification.dart';

/// Relatório de governança, risco e compliance (GRC).
class GovernanceReport extends ServiceReport {
  const GovernanceReport({
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
    required this.framework,
    required this.maturityByDomain,
    required this.targetMaturity,
    required this.gaps,
    required this.roadmapPhases,
    required this.estimatedInvestment,
    this.regulatoryDeadlines = const <DateTime>[],
  });

  /// Framework avaliado (ex.: "ISO 27001", "NIST CSF").
  final String framework;

  /// Maturidade atual por domínio de controle (0-5).
  final Map<String, double> maturityByDomain;
  final double targetMaturity;
  final List<String> gaps;
  final List<String> roadmapPhases;
  final double estimatedInvestment;

  /// Prazos regulatórios com data - alimenta o gatilho
  /// `regulatoryDeadlineRisk` (dispara quando algum vence em até 90 dias
  /// da entrega do relatório).
  final List<DateTime> regulatoryDeadlines;

  factory GovernanceReport.fromMap(String id, Map<String, Object?> map) {
    return GovernanceReport(
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
      framework: map['framework'] as String? ?? '',
      maturityByDomain: (map['maturityByDomain'] as Map<String, Object?>?)?.map(
            (String k, Object? v) =>
                MapEntry<String, double>(k, (v as num).toDouble()),
          ) ??
          const <String, double>{},
      targetMaturity: (map['targetMaturity'] as num?)?.toDouble() ?? 0,
      gaps: (map['gaps'] as List<dynamic>?)
              ?.map((Object? e) => e as String)
              .toList(growable: false) ??
          const <String>[],
      roadmapPhases: (map['roadmapPhases'] as List<dynamic>?)
              ?.map((Object? e) => e as String)
              .toList(growable: false) ??
          const <String>[],
      estimatedInvestment:
          (map['estimatedInvestment'] as num?)?.toDouble() ?? 0,
      regulatoryDeadlines: (map['regulatoryDeadlines'] as List<dynamic>?)
              ?.map((Object? e) => e as DateTime)
              .toList(growable: false) ??
          const <DateTime>[],
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
        'framework': framework,
        'maturityByDomain': maturityByDomain,
        'targetMaturity': targetMaturity,
        'gaps': gaps,
        'roadmapPhases': roadmapPhases,
        'estimatedInvestment': estimatedInvestment,
        'regulatoryDeadlines': regulatoryDeadlines,
      };
}
