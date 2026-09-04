import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/compliance_control.dart';
import '../domain/insight_item.dart';
import '../domain/posture_index.dart';
import '../domain/posture_snapshot.dart';
import '../domain/risk_item.dart';
import '../domain/security_domain.dart';
import '../domain/survey.dart';
import '../domain/tenant_profile.dart';

/// Único ponto que converte `Timestamp` do Firestore para [DateTime] no
/// módulo estratégico; o domínio não conhece o Firestore. Isolado de
/// `firestore_strategic_repository.dart` para manter aquele arquivo abaixo
/// do limite de 250 linhas.
DateTime toDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

Survey mapSurvey(
  QueryDocumentSnapshot<Map<String, dynamic>> surveyDoc,
  DocumentSnapshot<Map<String, dynamic>> responseDoc,
) {
  final Map<String, Object?> data = <String, Object?>{
    ...surveyDoc.data(),
    'id': surveyDoc.id,
  };
  final Map<String, dynamic>? responseData = responseDoc.data();
  final Map<String, String>? yourAnswers = responseData == null
      ? null
      : (responseData['answers'] as Map<String, dynamic>? ??
              const <String, dynamic>{})
          .map(
          (String key, Object? value) =>
              MapEntry<String, String>(key, value as String? ?? ''),
        );
  return Survey.fromMap(data, yourAnswers: yourAnswers);
}

PostureIndex mapPostureIndex(DocumentSnapshot<Map<String, dynamic>> doc) {
  final Map<String, Object?> data = doc.data() ?? const <String, Object?>{};
  final Map<String, dynamic> byDomainRaw =
      (data['byDomain'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
  final Map<SecurityDomain, int> byDomain = <SecurityDomain, int>{
    for (final MapEntry<String, dynamic> entry in byDomainRaw.entries)
      SecurityDomain.fromWire(entry.key): (entry.value as num?)?.toInt() ?? 0,
  };
  final Map<String, dynamic> byDomainDelta30dRaw =
      (data['byDomainDelta30d'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
  final Map<SecurityDomain, int> byDomainDelta30d = <SecurityDomain, int>{
    for (final MapEntry<String, dynamic> entry in byDomainDelta30dRaw.entries)
      SecurityDomain.fromWire(entry.key): (entry.value as num?)?.toInt() ?? 0,
  };
  return PostureIndex(
    overallScore: (data['overallScore'] as num?)?.toInt() ?? 0,
    previousScore: (data['previousScore'] as num?)?.toInt() ?? 0,
    capturedAt: toDateTime(data['capturedAt']),
    byDomain: byDomain,
    peerMedian: (data['peerMedian'] as num?)?.toInt() ?? 0,
    byDomainDelta30d: byDomainDelta30d,
  );
}

PostureSnapshot mapPostureSnapshot(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final Map<String, dynamic> data = doc.data();
  return PostureSnapshot.fromMap(<String, Object?>{
    ...data,
    'capturedAt': toDateTime(data['capturedAt']),
  });
}

ComplianceControl mapComplianceControl(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final Map<String, dynamic> data = doc.data();
  return ComplianceControl.fromMap(<String, Object?>{
    ...data,
    'controlId': data['controlId'] ?? doc.id,
    'lastReviewedAt': toDateTime(data['lastReviewedAt']),
  });
}

RiskItem mapRiskItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final Map<String, dynamic> data = doc.data();
  return RiskItem.fromMap(<String, Object?>{
    ...data,
    'id': data['id'] ?? doc.id,
    'reviewDueAt': toDateTime(data['reviewDueAt']),
  });
}

InsightItem mapInsightItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final Map<String, dynamic> data = doc.data();
  return InsightItem.fromMap(<String, Object?>{
    ...data,
    'id': data['id'] ?? doc.id,
    'publishedAt': toDateTime(data['publishedAt']),
  });
}

TenantProfile mapTenantProfile(DocumentSnapshot<Map<String, dynamic>> doc) {
  final Map<String, Object?> data = doc.data() ?? const <String, Object?>{};
  return TenantProfile.fromMap(data);
}
