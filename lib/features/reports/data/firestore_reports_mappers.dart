import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/appsec_report.dart';
import '../domain/models/attack_surface_report.dart';
import '../domain/models/defense_report.dart';
import '../domain/models/governance_report.dart';
import '../domain/models/incident_response_report.dart';
import '../domain/models/pentest_report.dart';
import '../domain/models/third_party_report.dart';
import '../domain/models/vuln_management_report.dart';
import '../domain/report.dart';
import '../domain/report_section.dart';

/// Único ponto que converte `Timestamp` do Firestore para [DateTime] no
/// módulo de relatórios; o domínio não conhece o Firestore. Isolado de
/// `firestore_reports_repository.dart` para manter aquele arquivo abaixo
/// do limite de 250 linhas.
DateTime _ts(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

DateTime? _tsOrNull(Object? value) => value == null ? null : _ts(value);

Map<String, Object?> _convertDates(Map<String, dynamic> data) {
  final Map<String, Object?> out = <String, Object?>{...data};
  out['deliveredAt'] = _ts(data['deliveredAt']);
  out['containmentAt'] = _tsOrNull(data['containmentAt']);
  out['eradicationAt'] = _tsOrNull(data['eradicationAt']);
  out['materialFacts'] = <Map<String, Object?>>[
    for (final dynamic f
        in (data['materialFacts'] as List<dynamic>? ?? const []))
      <String, Object?>{
        ...(f as Map<String, dynamic>),
        'detectedAt': _ts(f['detectedAt']),
      },
  ];
  out['nextSteps'] = <Map<String, Object?>>[
    for (final dynamic a in (data['nextSteps'] as List<dynamic>? ?? const []))
      <String, Object?>{
        ...(a as Map<String, dynamic>),
        'dueAt': _ts(a['dueAt']),
      },
  ];
  out['incidentTimeline'] = <Map<String, Object?>>[
    for (final dynamic e
        in (data['incidentTimeline'] as List<dynamic>? ?? const []))
      <String, Object?>{
        ...(e as Map<String, dynamic>),
        'occurredAt': _ts(e['occurredAt']),
      },
  ];
  return out;
}

/// Constrói o modelo especialista correto a partir de `category` - o campo
/// que amarra o documento a um dos 8 modelos do prompt 11.
ServiceReport mapReportDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) =>
    mapReportData(doc.id, doc.data());

ServiceReport mapReportData(String id, Map<String, dynamic> raw) {
  final Map<String, Object?> data = _convertDates(raw);
  final String category = raw['category'] as String? ?? '';
  switch (category) {
    case 'pentest':
      return PentestReport.fromMap(id, data);
    case 'appsec':
      return AppSecReport.fromMap(id, data);
    case 'attack_surface':
      return AttackSurfaceReport.fromMap(id, data);
    case 'response':
      return IncidentResponseReport.fromMap(id, data);
    case 'governance':
      return GovernanceReport.fromMap(id, data);
    case 'vulnerability':
      return VulnManagementReport.fromMap(id, data);
    case 'third_party':
      return ThirdPartyReport.fromMap(id, data);
    case 'defense':
      return DefenseReport.fromMap(id, data);
    default:
      throw StateError('Categoria de relatório desconhecida: "$category".');
  }
}

ReportSection mapReportSectionDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) =>
    ReportSection.fromMap(doc.data());
