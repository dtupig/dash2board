import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../domain/report.dart';
import '../domain/report_section.dart';
import 'firestore_reports_repository.dart';
import 'mock_reports_repository.dart';
import 'reports_repository.dart';

/// Repositório de dados de relatórios - único ponto do app que sabe se os
/// dados vêm do mock ou do Firestore.
final Provider<ReportsRepository> reportsRepositoryProvider =
    Provider<ReportsRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockReportsRepository();
  }
  return FirestoreReportsRepository();
});

String? _watchTenantId(Ref ref) {
  final String? tenantId = ref.watch(appUserProvider).value?.tenantId;
  return (tenantId == null || tenantId.isEmpty) ? null : tenantId;
}

/// Relatórios visíveis para a persona logada - já filtrados pela alçada
/// (`ReportAccessPolicy`, espelhado em `firestore.rules`).
final StreamProvider<List<ServiceReport>> reportsProvider =
    StreamProvider<List<ServiceReport>>((ref) {
  final String? tenantId = _watchTenantId(ref);
  final String? roleWire = ref.watch(appUserProvider).value?.role.wireValue;
  if (tenantId == null || roleWire == null) {
    return Stream<List<ServiceReport>>.value(const <ServiceReport>[]);
  }
  return ref
      .watch(reportsRepositoryProvider)
      .watchReports(tenantId: tenantId, roleWire: roleWire);
});

final reportProvider =
    StreamProvider.family<ServiceReport?, String>((ref, reportId) {
  final String? tenantId = _watchTenantId(ref);
  if (tenantId == null) {
    return Stream<ServiceReport?>.value(null);
  }
  return ref.watch(reportsRepositoryProvider).watchReport(tenantId, reportId);
});

final reportSectionsProvider =
    StreamProvider.family<List<ReportSection>, String>((ref, reportId) {
  final String? tenantId = _watchTenantId(ref);
  final String? roleWire = ref.watch(appUserProvider).value?.role.wireValue;
  if (tenantId == null || roleWire == null) {
    return Stream<List<ReportSection>>.value(const <ReportSection>[]);
  }
  return ref
      .watch(reportsRepositoryProvider)
      .watchSections(tenantId, reportId, roleWire: roleWire);
});
