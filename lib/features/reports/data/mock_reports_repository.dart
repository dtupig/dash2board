import '../../auth/domain/user_role.dart';
import '../domain/report.dart';
import '../domain/report_access_policy.dart';
import '../domain/report_section.dart';
import 'mock/mock_report_sections.dart';
import 'mock/mock_reports_defense.dart';
import 'mock/mock_reports_incident.dart';
import 'mock/mock_reports_other.dart';
import 'mock/mock_reports_pentest.dart';
import 'mock/mock_reports_vuln.dart';
import 'reports_repository.dart';

/// Dados de demonstração dos relatórios especialistas, 100% em memória.
///
/// Mesma data de referência fixa das outras demonstrações do app, para que
/// a narrativa seja reproduzível. Os 8 relatórios de exemplo (um por
/// categoria, dois deles com uma segunda entrega) vivem em
/// `data/mock/mock_reports_*.dart`, um arquivo por categoria, para manter
/// este arquivo abaixo do limite de 250 linhas.
class MockReportsRepository implements ReportsRepository {
  static const Duration _streamDelay = Duration(milliseconds: 400);
  static final DateTime _anchor = DateTime.utc(2026, 8, 1);

  final Set<String> _readReceipts = <String>{};

  late final List<ServiceReport> _reports = <ServiceReport>[
    ...mockPentestReports(_anchor),
    ...mockDefenseReports(_anchor),
    ...mockIncidentReports(_anchor),
    ...mockVulnManagementReports(_anchor),
    mockAppSecReport(_anchor),
    mockAttackSurfaceReport(_anchor),
    mockGovernanceReport(_anchor),
    mockThirdPartyReport(_anchor),
  ];

  @override
  Stream<List<ServiceReport>> watchReports({
    required String tenantId,
    required String roleWire,
  }) {
    final UserRole role = UserRole.fromWire(roleWire);
    return _afterDelay(() => _reports
        .where((ServiceReport r) => ReportAccessPolicy.canOpen(
              role,
              r.classification,
              isMaterialFact: r.hasMaterialFact,
            ))
        .toList(growable: false));
  }

  @override
  Stream<ServiceReport?> watchReport(String tenantId, String reportId) {
    return _afterDelay(() {
      for (final ServiceReport r in _reports) {
        if (r.id == reportId) {
          return r;
        }
      }
      return null;
    });
  }

  @override
  Stream<List<ReportSection>> watchSections(String tenantId, String reportId) {
    return _afterDelay(() {
      for (final ServiceReport r in _reports) {
        if (r.id == reportId) {
          return buildMockSections(r);
        }
      }
      return const <ReportSection>[];
    });
  }

  @override
  Future<void> recordReadReceipt({
    required String tenantId,
    required String reportId,
    required String uid,
  }) async {
    await Future<void>.delayed(_streamDelay);
    _readReceipts.add('$tenantId/$reportId/$uid');
  }

  /// Exposto só para teste - confirma que o registro foi de fato gravado
  /// antes da renderização do conteúdo `secret`.
  bool hasReadReceipt(String tenantId, String reportId, String uid) =>
      _readReceipts.contains('$tenantId/$reportId/$uid');

  Stream<T> _afterDelay<T>(T Function() compute) async* {
    await Future<void>.delayed(_streamDelay);
    yield compute();
  }
}
