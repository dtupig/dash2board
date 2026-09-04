import '../action_item.dart';
import '../delivery_kind.dart';
import '../material_fact.dart';
import '../report.dart';
import '../report_attachment.dart';
import '../report_classification.dart';
import 'incident_timeline_event.dart';

/// Relatório de resposta a incidente, perícia forense ou UAM.
///
/// Campos de custódia (`deviceIdentifiers`/`cloudResourceIdentifiers`/
/// `acquisitionHash`/`custodianName`/`acquisitionMethod`) só existem nos
/// serviços de coleta forense - `forensics_cloud` usa
/// `cloudResourceIdentifiers` em vez de `deviceIdentifiers`, porque a
/// evidência é um recurso de nuvem, não um dispositivo físico (D-27,
/// gap #13). Sem amostra real disponível, o mock usa os templates
/// genéricos e sintéticos de `docs/templates/` (`isGeneric: true`).
class IncidentResponseReport extends ServiceReport {
  const IncidentResponseReport({
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
    required this.incidentTimeline,
    required this.initialVector,
    this.dwellTimeHours,
    this.containmentAt,
    this.eradicationAt,
    this.iocs = const <String>[],
    this.chainOfCustody,
    this.affectedDataSubjects = const <String>[],
    required this.regulatoryNotificationRequired,
    required this.lessonsLearned,
    this.exerciseScore,
    this.forensicStandardsApplied = const <String>[],
    this.deviceIdentifiers,
    this.cloudResourceIdentifiers,
    this.acquisitionHash,
    this.custodianName,
    this.acquisitionMethod,
    this.monitoredUsers = const <String>[],
    this.monitoringLegalBasis,

    /// Ameaça objetiva e explícita à continuidade de um processo crítico de
    /// negócio - gatilho `businessContinuityRisk`. Campo direto, não
    /// inferido de outros campos: `MaterialFactEvaluator` não usa
    /// heurística implícita.
    this.businessContinuityThreatened = false,
  });

  final List<IncidentTimelineEvent> incidentTimeline;
  final String initialVector;
  final int? dwellTimeHours;
  final DateTime? containmentAt;
  final DateTime? eradicationAt;

  /// [SectionSensitivity.technical].
  final List<String> iocs;

  /// [SectionSensitivity.chainOfCustody].
  final String? chainOfCustody;

  /// [SectionSensitivity.personalData].
  final List<String> affectedDataSubjects;
  final bool regulatoryNotificationRequired;
  final String lessonsLearned;
  final double? exerciseScore;
  final List<String> forensicStandardsApplied;
  final Map<String, String>? deviceIdentifiers;
  final Map<String, String>? cloudResourceIdentifiers;
  final String? acquisitionHash;
  final String? custodianName;
  final String? acquisitionMethod;
  final List<String> monitoredUsers;
  final String? monitoringLegalBasis;
  final bool businessContinuityThreatened;

  static Map<String, String>? _stringMap(Object? value) {
    final Map<String, Object?>? map = value as Map<String, Object?>?;
    if (map == null) {
      return null;
    }
    return map.map(
      (String k, Object? v) => MapEntry<String, String>(k, v as String? ?? ''),
    );
  }

  static List<String> _stringList(Object? value) {
    return (value as List<dynamic>?)
            ?.map((Object? e) => e as String)
            .toList(growable: false) ??
        const <String>[];
  }

  factory IncidentResponseReport.fromMap(String id, Map<String, Object?> map) {
    return IncidentResponseReport(
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
      incidentTimeline: (map['incidentTimeline'] as List<dynamic>?)
              ?.map((Object? e) =>
                  IncidentTimelineEvent.fromMap(e as Map<String, Object?>))
              .toList(growable: false) ??
          const <IncidentTimelineEvent>[],
      initialVector: map['initialVector'] as String? ?? '',
      dwellTimeHours: (map['dwellTimeHours'] as num?)?.toInt(),
      containmentAt: map['containmentAt'] as DateTime?,
      eradicationAt: map['eradicationAt'] as DateTime?,
      iocs: _stringList(map['iocs']),
      chainOfCustody: map['chainOfCustody'] as String?,
      affectedDataSubjects: _stringList(map['affectedDataSubjects']),
      regulatoryNotificationRequired:
          map['regulatoryNotificationRequired'] as bool? ?? false,
      lessonsLearned: map['lessonsLearned'] as String? ?? '',
      exerciseScore: (map['exerciseScore'] as num?)?.toDouble(),
      forensicStandardsApplied: _stringList(map['forensicStandardsApplied']),
      deviceIdentifiers: _stringMap(map['deviceIdentifiers']),
      cloudResourceIdentifiers: _stringMap(map['cloudResourceIdentifiers']),
      acquisitionHash: map['acquisitionHash'] as String?,
      custodianName: map['custodianName'] as String?,
      acquisitionMethod: map['acquisitionMethod'] as String?,
      monitoredUsers: _stringList(map['monitoredUsers']),
      monitoringLegalBasis: map['monitoringLegalBasis'] as String?,
      businessContinuityThreatened:
          map['businessContinuityThreatened'] as bool? ?? false,
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
        'incidentTimeline': <Map<String, Object?>>[
          for (final IncidentTimelineEvent e in incidentTimeline) e.toMap(),
        ],
        'initialVector': initialVector,
        'dwellTimeHours': dwellTimeHours,
        'containmentAt': containmentAt,
        'eradicationAt': eradicationAt,
        'iocs': iocs,
        'chainOfCustody': chainOfCustody,
        'affectedDataSubjects': affectedDataSubjects,
        'regulatoryNotificationRequired': regulatoryNotificationRequired,
        'lessonsLearned': lessonsLearned,
        'exerciseScore': exerciseScore,
        'forensicStandardsApplied': forensicStandardsApplied,
        'deviceIdentifiers': deviceIdentifiers,
        'cloudResourceIdentifiers': cloudResourceIdentifiers,
        'acquisitionHash': acquisitionHash,
        'custodianName': custodianName,
        'acquisitionMethod': acquisitionMethod,
        'monitoredUsers': monitoredUsers,
        'monitoringLegalBasis': monitoringLegalBasis,
        'businessContinuityThreatened': businessContinuityThreatened,
      };
}
