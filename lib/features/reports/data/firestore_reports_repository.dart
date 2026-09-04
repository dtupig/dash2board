import 'package:cloud_firestore/cloud_firestore.dart';

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
class FirestoreReportsRepository implements ReportsRepository {
  FirestoreReportsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
  Stream<List<ReportSection>> watchSections(String tenantId, String reportId) {
    return _firestore
        .collection(FirestorePaths.reportSections(tenantId, reportId))
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
    // projeto) - o registro de leitura de `secret` é gravado por Cloud
    // Function acionada por este mesmo evento de abertura, fora do escopo
    // deste app cliente.
    return;
  }

  Never _rethrowAsFailure(Object error, StackTrace stackTrace) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      throw const AppFailure.accessNotProvisioned();
    }
    throw const AppFailure.network();
  }
}
