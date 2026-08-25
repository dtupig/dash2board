import '../action_item.dart';
import '../delivery_kind.dart';
import '../material_fact.dart';
import '../report.dart';
import '../report_attachment.dart';
import '../report_classification.dart';

/// Relatório de defesa e inteligência de ameaças.
class DefenseReport extends ServiceReport {
  const DefenseReport({
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
    required this.controlCoverage,
    required this.detectionsByTactic,
    required this.tuningActions,
    required this.falsePositiveReduction,
    required this.phishingClickRate,
    required this.credentialsFoundInLeaks,
    required this.hardeningRecommendations,
    this.relatedSurfaceFindings = const <String>[],
  });

  /// % de cobertura de controle de defesa (EDR/e-mail/WAF).
  final double controlCoverage;

  /// Detecções por tática MITRE ATT&CK -> contagem.
  final Map<String, int> detectionsByTactic;
  final List<String> tuningActions;
  final double falsePositiveReduction;
  final double phishingClickRate;

  /// [SectionSensitivity.personalData] - credenciais corporativas achadas
  /// em vazamento público. Alimenta os gatilhos `personalDataExposure` e
  /// `leakedCorporateCredentials`.
  final List<String> credentialsFoundInLeaks;
  final List<String> hardeningRecommendations;

  /// Resumo leve de achados de reconhecimento de superfície - resolve o
  /// caso real de TI disparada por incidente, que produz dado
  /// `AttackSurfaceReport`-shaped no mesmo documento (D-27, decisão 1:
  /// bloco opcional aqui, não sub-variante nem fusão de modelo).
  final List<String> relatedSurfaceFindings;

  factory DefenseReport.fromMap(String id, Map<String, Object?> map) {
    return DefenseReport(
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
      controlCoverage: (map['controlCoverage'] as num?)?.toDouble() ?? 0,
      detectionsByTactic:
          (map['detectionsByTactic'] as Map<String, Object?>?)?.map(
                (String k, Object? v) =>
                    MapEntry<String, int>(k, (v as num).toInt()),
              ) ??
              const <String, int>{},
      tuningActions: (map['tuningActions'] as List<dynamic>?)
              ?.map((Object? e) => e as String)
              .toList(growable: false) ??
          const <String>[],
      falsePositiveReduction:
          (map['falsePositiveReduction'] as num?)?.toDouble() ?? 0,
      phishingClickRate: (map['phishingClickRate'] as num?)?.toDouble() ?? 0,
      credentialsFoundInLeaks:
          (map['credentialsFoundInLeaks'] as List<dynamic>?)
                  ?.map((Object? e) => e as String)
                  .toList(growable: false) ??
              const <String>[],
      hardeningRecommendations:
          (map['hardeningRecommendations'] as List<dynamic>?)
                  ?.map((Object? e) => e as String)
                  .toList(growable: false) ??
              const <String>[],
      relatedSurfaceFindings: (map['relatedSurfaceFindings'] as List<dynamic>?)
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
        'controlCoverage': controlCoverage,
        'detectionsByTactic': detectionsByTactic,
        'tuningActions': tuningActions,
        'falsePositiveReduction': falsePositiveReduction,
        'phishingClickRate': phishingClickRate,
        'credentialsFoundInLeaks': credentialsFoundInLeaks,
        'hardeningRecommendations': hardeningRecommendations,
        'relatedSurfaceFindings': relatedSurfaceFindings,
      };
}
