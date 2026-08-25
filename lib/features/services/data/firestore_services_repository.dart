import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firestore_paths.dart';
import '../../../core/errors/app_failure.dart';
import '../../auth/domain/user_role.dart';
import '../domain/approval_record.dart';
import '../domain/contracted_service.dart';
import '../domain/request_driver.dart';
import '../domain/request_policy.dart';
import '../domain/request_status.dart';
import '../domain/request_urgency.dart';
import '../domain/service_request.dart';
import 'firestore_services_mappers.dart';
import 'services_repository.dart';

/// Implementação de produção sobre Cloud Firestore.
///
/// Espelha exatamente as permissões de `firestore.rules`: quando uma escrita
/// é rejeitada pelo backend, a exceção vira [AppFailure] antes de chegar à
/// UI - o domínio nunca vê uma `FirebaseException`. As funções de
/// mapeamento vivem em `firestore_services_mappers.dart`, para manter este
/// arquivo abaixo do limite de 250 linhas.
class FirestoreServicesRepository implements ServicesRepository {
  FirestoreServicesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<ContractedService>> watchContractedServices(String tenantId) {
    return _firestore
        .collection(FirestorePaths.contractedServices(tenantId))
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.docs.map(mapContractedServiceDoc).toList(growable: false))
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<List<ServiceRequest>> watchRequests({
    required String tenantId,
    required String roleWire,
    String? requesterUid,
  }) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(FirestorePaths.serviceRequests(tenantId));
    if (roleWire == 'operational' && requesterUid != null) {
      query = query.where('requestedByUid', isEqualTo: requesterUid);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map(mapServiceRequestQueryDoc)
            .toList(growable: false))
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<ServiceRequest?> watchRequest(String tenantId, String requestId) {
    return _firestore
        .doc(FirestorePaths.serviceRequest(tenantId, requestId))
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
            doc.exists ? mapServiceRequestDoc(doc) : null)
        .handleError(_rethrowAsFailure);
  }

  @override
  Future<String> createRequest({
    required String tenantId,
    required String serviceKey,
    required String requestedByUid,
    required String requestedByName,
    required String openerRoleWire,
    required RequestUrgency urgency,
    required RequestDriver driver,
    required String scopeSummary,
    required List<String> scopeAssets,
    required String businessJustification,
    required DateTime desiredWindow,
  }) async {
    final bool selfApproves =
        !RequestPolicy.requiresApproval(UserRole.fromWire(openerRoleWire));
    final RequestStatus status =
        selfApproves ? RequestStatus.approved : RequestStatus.pendingApproval;
    try {
      final DocumentReference<Map<String, dynamic>> ref =
          _firestore.collection(FirestorePaths.serviceRequests(tenantId)).doc();
      await ref.set(<String, Object?>{
        'tenantId': tenantId,
        'serviceKey': serviceKey,
        'requestedByUid': requestedByUid,
        'requestedByName': requestedByName,
        'createdAt': FieldValue.serverTimestamp(),
        'urgency': urgency.wireValue,
        'driver': driver.wireValue,
        'scopeSummary': scopeSummary,
        'scopeAssets': scopeAssets,
        'businessJustification': businessJustification,
        'desiredWindow': Timestamp.fromDate(desiredWindow),
        'status': status.wireValue,
        'approval': selfApproves
            ? ApprovalRecord(
                decidedByUid: requestedByUid,
                decidedByName: requestedByName,
                decidedAt: DateTime.now(),
                decision: ApprovalDecision.approved,
                isSelfApproval: true,
              ).toMap()
            : null,
        'timeline': <Map<String, Object?>>[
          <String, Object?>{
            'status': status.wireValue,
            'occurredAt': Timestamp.now(),
            'note': '',
          },
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException catch (error, stackTrace) {
      _rethrowAsFailure(error, stackTrace);
    }
  }

  @override
  Future<void> submitForApproval(String tenantId, String requestId) async {
    try {
      await _firestore
          .doc(FirestorePaths.serviceRequest(tenantId, requestId))
          .update(<String, Object?>{
        'status': RequestStatus.pendingApproval.wireValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      _rethrowAsFailure(error, stackTrace);
    }
  }

  @override
  Future<void> decideApproval({
    required String tenantId,
    required String requestId,
    required ApprovalDecision decision,
    required String decidedByUid,
    required String decidedByName,
    required String note,
  }) async {
    if (decision == ApprovalDecision.rejected && note.trim().isEmpty) {
      throw ArgumentError('Rejeição exige nota - nunca sem justificativa.');
    }
    final RequestStatus next = decision == ApprovalDecision.approved
        ? RequestStatus.approved
        : RequestStatus.rejected;
    try {
      await _firestore
          .doc(FirestorePaths.serviceRequest(tenantId, requestId))
          .update(<String, Object?>{
        'status': next.wireValue,
        'approval': ApprovalRecord(
          decidedByUid: decidedByUid,
          decidedByName: decidedByName,
          decidedAt: DateTime.now(),
          decision: decision,
          note: note,
        ).toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      _rethrowAsFailure(error, stackTrace);
    }
  }

  @override
  Future<void> cancelRequest(String tenantId, String requestId) async {
    try {
      await _firestore
          .doc(FirestorePaths.serviceRequest(tenantId, requestId))
          .update(<String, Object?>{
        'status': RequestStatus.cancelled.wireValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      _rethrowAsFailure(error, stackTrace);
    }
  }

  Never _rethrowAsFailure(Object error, StackTrace stackTrace) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      throw const AppFailure.accessNotProvisioned();
    }
    throw const AppFailure.network();
  }
}
