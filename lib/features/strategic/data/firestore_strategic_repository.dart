import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firestore_paths.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/compliance_control.dart';
import '../domain/insight_item.dart';
import '../domain/posture_index.dart';
import '../domain/posture_snapshot.dart';
import '../domain/risk_item.dart';
import '../domain/security_domain.dart';
import '../domain/survey.dart';
import '../domain/tenant_profile.dart';
import 'strategic_repository.dart';

/// Implementação de produção sobre Cloud Firestore.
///
/// Único ponto do app que converte `Timestamp` para [DateTime]: o domínio
/// não conhece o Firestore. Qualquer exceção do SDK vira [AppFailure] antes
/// de chegar à UI — nunca deixamos uma `FirebaseException` vazar pelo
/// `AsyncValue.error` de um `StreamProvider`.
class FirestoreStrategicRepository implements StrategicRepository {
  FirestoreStrategicRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Documento agregado com o índice de postura de hoje, pré-calculado por
  /// Cloud Function para custar uma única leitura.
  static const String _postureIndexMetricId = 'posture_index';

  @override
  Stream<PostureIndex> watchPostureIndex(String tenantId) {
    return _firestore
        .doc(FirestorePaths.metric(tenantId, _postureIndexMetricId))
        .snapshots()
        .map(_mapPostureIndex)
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<List<PostureSnapshot>> watchPostureHistory(
    String tenantId, {
    int months = 12,
  }) {
    return _firestore
        .collection(FirestorePaths.postureSnapshots(tenantId))
        .orderBy('capturedAt', descending: true)
        .limit(months)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map(_mapPostureSnapshot)
            .toList(growable: false)
            .reversed
            .toList(growable: false))
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<List<ComplianceControl>> watchCompliance(
    String tenantId, {
    ComplianceFramework? framework,
  }) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(FirestorePaths.compliance(tenantId));
    if (framework != null) {
      query = query.where('framework', isEqualTo: framework.wireValue);
    }
    return query
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.docs.map(_mapComplianceControl).toList(growable: false))
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<List<RiskItem>> watchTopRisks(String tenantId, {int limit = 5}) {
    return _firestore
        .collection(FirestorePaths.risks(tenantId))
        .orderBy('annualLossExpectancy', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.docs.map(_mapRiskItem).toList(growable: false))
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<List<RiskItem>> watchAllRisks(String tenantId) {
    return _firestore
        .collection(FirestorePaths.risks(tenantId))
        .orderBy('annualLossExpectancy', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.docs.map(_mapRiskItem).toList(growable: false))
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<TenantProfile> watchTenantProfile(String tenantId) {
    return _firestore
        .doc(FirestorePaths.tenant(tenantId))
        .snapshots()
        .map(_mapTenantProfile)
        .handleError(_rethrowAsFailure);
  }

  @override
  Future<void> recordRiskDecision({
    required String tenantId,
    required String riskId,
    required RiskAcceptance decision,
    required String actorUid,
    required String boardNote,
  }) async {
    try {
      // Só os campos que `firestore.rules` libera para o papel `board` -
      // nenhum outro campo do risco muda aqui.
      await _firestore
          .doc('${FirestorePaths.risks(tenantId)}/$riskId')
          .update(<String, Object?>{
        'acceptance': decision.wireValue,
        'acceptedByUid': actorUid,
        'acceptedAt': FieldValue.serverTimestamp(),
        'boardNote': boardNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      _rethrowAsFailure(error, stackTrace);
    }
  }

  @override
  Stream<List<InsightItem>> watchInsights(String tenantId, {int limit = 10}) {
    return _firestore
        .collection(FirestorePaths.insights(tenantId))
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.docs.map(_mapInsightItem).toList(growable: false))
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<Survey?> watchActiveSurvey(String tenantId, String uid) {
    return _firestore
        .collection(FirestorePaths.surveys(tenantId))
        .where('active', isEqualTo: true)
        .limit(1)
        .snapshots()
        .asyncMap((QuerySnapshot<Map<String, dynamic>> snapshot) async {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final QueryDocumentSnapshot<Map<String, dynamic>> surveyDoc =
          snapshot.docs.first;
      final DocumentSnapshot<Map<String, dynamic>> responseDoc =
          await _firestore
              .doc(FirestorePaths.surveyResponse(tenantId, surveyDoc.id, uid))
              .get();
      return _mapSurvey(surveyDoc, responseDoc);
    }).handleError(_rethrowAsFailure);
  }

  @override
  Future<void> submitSurveyResponse({
    required String tenantId,
    required String surveyId,
    required String uid,
    required Map<String, String> answers,
  }) async {
    try {
      await _firestore
          .doc(FirestorePaths.surveyResponse(tenantId, surveyId, uid))
          .set(<String, Object?>{
        'answers': answers,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      _rethrowAsFailure(error, stackTrace);
    }
  }

  Survey _mapSurvey(
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

  PostureIndex _mapPostureIndex(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, Object?> data = doc.data() ?? const <String, Object?>{};
    final Map<String, dynamic> byDomainRaw =
        (data['byDomain'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};
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
      capturedAt: _toDateTime(data['capturedAt']),
      byDomain: byDomain,
      peerMedian: (data['peerMedian'] as num?)?.toInt() ?? 0,
      byDomainDelta30d: byDomainDelta30d,
    );
  }

  PostureSnapshot _mapPostureSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();
    return PostureSnapshot.fromMap(<String, Object?>{
      ...data,
      'capturedAt': _toDateTime(data['capturedAt']),
    });
  }

  ComplianceControl _mapComplianceControl(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();
    return ComplianceControl.fromMap(<String, Object?>{
      ...data,
      'controlId': data['controlId'] ?? doc.id,
      'lastReviewedAt': _toDateTime(data['lastReviewedAt']),
    });
  }

  RiskItem _mapRiskItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();
    return RiskItem.fromMap(<String, Object?>{
      ...data,
      'id': data['id'] ?? doc.id,
      'reviewDueAt': _toDateTime(data['reviewDueAt']),
    });
  }

  InsightItem _mapInsightItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();
    return InsightItem.fromMap(<String, Object?>{
      ...data,
      'id': data['id'] ?? doc.id,
      'publishedAt': _toDateTime(data['publishedAt']),
    });
  }

  TenantProfile _mapTenantProfile(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, Object?> data = doc.data() ?? const <String, Object?>{};
    return TenantProfile.fromMap(data);
  }

  DateTime _toDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  /// Converte qualquer erro do SDK em [AppFailure] antes de repassar ao
  /// `Stream`. Lançar dentro de `handleError` substitui o erro original pelo
  /// que é lançado aqui, então a UI nunca vê uma `FirebaseException`.
  Never _rethrowAsFailure(Object error, StackTrace stackTrace) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      throw const AppFailure.accessNotProvisioned();
    }
    throw const AppFailure.network();
  }
}
