import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/config/firestore_paths.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/report.dart';
import '../domain/report_section.dart';
import 'firestore_reports_mappers.dart';
import 'reports_repository.dart';

/// Implementação de produção sobre Cloud Firestore.
///
/// A filtragem por persona já acontece em `firestore.rules` (espelhando
/// `ReportAccessPolicy`) - a query aqui só ordena e delega ao backend a
/// decisão de o que cada leitor alcança. As funções de mapeamento vivem em
/// `firestore_reports_mappers.dart`, para manter este arquivo abaixo do
/// limite de 250 linhas.
///
/// `watchReports` filtra por `audienceRoles` (`array-contains: roleWire`)
/// porque a regra de `list` em `firestore.rules` precisa ser decidível por
/// documento sem overhead de `get()` - sem esse `where`, um único
/// relatório que o papel não alcance derruba a query inteira com
/// `permission-denied` (achado 1, docs/20_RETOMADA_SESSAO.md).
/// `watchSections` filtra por `visibleRoles` pelo mesmo motivo (achado 5).
///
/// `recordReadReceipt` invoca a Cloud Function homônima em vez de escrever
/// direto - o cliente nunca escreve em `audit_logs` (achado 2).
class FirestoreReportsRepository implements ReportsRepository {
  FirestoreReportsRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<ServiceReport>> watchReports({
    required String tenantId,
    required String roleWire,
  }) {
    return _firestore
        .collection(FirestorePaths.reports(tenantId))
        .where('audienceRoles', arrayContains: roleWire)
        .orderBy('deliveredAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.docs.map(mapReportDoc).toList(growable: false))
        .handleError(_rethrowAsFailure);
  }

  @override
  Stream<ServiceReport?> watchReport(String tenantId, String reportId) {
    return _firestore
        .doc(FirestorePaths.report(tenantId, reportId))
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic>? data = doc.data();
      return data == null ? null : mapReportData(doc.id, data);
    }).handleError(_rethrowAsFailure);
  }

  @override
  Stream<List<ReportSection>> watchSections(
    String tenantId,
    String reportId, {
    required String roleWire,
  }) {
    return _firestore
        .collection(FirestorePaths.reportSections(tenantId, reportId))
        .where('visibleRoles', arrayContains: roleWire)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.docs.map(mapReportSectionDoc).toList(growable: false))
        .handleError(_rethrowAsFailure);
  }

  @override
  Future<void> recordReadReceipt({
    required String tenantId,
    required String reportId,
    required String uid,
  }) async {
    // O client SDK não escreve em `audit_logs` (regra fail-closed do
    // projeto) - quem grava o registro de leitura é a Cloud Function
    // `recordReadReceipt`, que recalcula o acesso a partir do documento
    // real via Admin SDK em vez de confiar no que o cliente afirma.
    try {
      await _functions.httpsCallable('recordReadReceipt').call<void>(
        <String, Object?>{'reportId': reportId},
      );
    } on FirebaseFunctionsException catch (error, stackTrace) {
      _rethrowAsFailure(error, stackTrace);
    }
  }

  Never _rethrowAsFailure(Object error, StackTrace stackTrace) {
    if (error is FirebaseFunctionsException &&
        (error.code == 'permission-denied' || error.code == 'not-found')) {
      throw const AppFailure.accessNotProvisioned();
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      throw const AppFailure.accessNotProvisioned();
    }
    throw const AppFailure.network();
  }
}
