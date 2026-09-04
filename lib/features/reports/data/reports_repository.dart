import '../domain/report.dart';
import '../domain/report_section.dart';

/// Contrato de dados do módulo de relatórios especialistas.
///
/// Duas implementações, escolhidas uma única vez em `reports_providers.dart`:
/// [MockReportsRepository] (demonstração offline) e
/// [FirestoreReportsRepository] (produção).
abstract interface class ReportsRepository {
  /// Relatórios visíveis para [roleWire], já filtrados pela alçada da
  /// persona (espelhando `ReportAccessPolicy.canOpen`): `operational` e
  /// `strategic` veem os do tenant conforme classificação; `board` só os
  /// que já têm fato relevante ou são `public_internal`.
  Stream<List<ServiceReport>> watchReports({
    required String tenantId,
    required String roleWire,
  });

  Stream<ServiceReport?> watchReport(String tenantId, String reportId);

  /// Seções do relatório - subcoleção separada porque o conteúdo pode ser
  /// grande e nem toda seção é lida em toda visita. [roleWire] filtra pela
  /// mesma alçada de [watchReports] (espelhando `ReportAccessPolicy.
  /// canSeeSection`), pelo mesmo motivo: a implementação Firestore precisa
  /// de um `where` que replique a regra de segurança para não derrubar a
  /// lista inteira quando uma única seção estiver fora do alcance do papel.
  Stream<List<ReportSection>> watchSections(
    String tenantId,
    String reportId, {
    required String roleWire,
  });

  /// Grava o registro de leitura exigido antes de renderizar um relatório
  /// `secret` (`ReportAccessPolicy.requiresReadReceipt`). No mock, fica só
  /// em memória; no Firestore, vira uma entrada em `audit_logs`.
  Future<void> recordReadReceipt({
    required String tenantId,
    required String reportId,
    required String uid,
  });
}
