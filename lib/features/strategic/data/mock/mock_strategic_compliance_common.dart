import '../../domain/compliance_control.dart';
import '../../domain/security_domain.dart';
import 'mock_strategic_dates.dart';

/// Builder compartilhado pelos dois arquivos de controle de compliance
/// (`mock_strategic_compliance_iso_nist.dart` e
/// `..._lgpd_pci.dart`) - evita duplicar a regra de evidência entre eles.
ComplianceControl buildComplianceControl({
  required DateTime anchor,
  required ComplianceFramework framework,
  required String controlId,
  required String title,
  required ControlStatus status,
  required String ownerName,
  required int reviewedDaysAgo,
  required SecurityDomain domain,
}) {
  final String url = status == ControlStatus.gap
      ? ''
      : 'https://evidencias.elytronsecurity.com/tenant-demo/$controlId';
  return ComplianceControl(
    framework: framework,
    controlId: controlId,
    title: title,
    status: status,
    ownerName: ownerName,
    lastReviewedAt: daysBefore(anchor, reviewedDaysAgo),
    domain: domain,
    evidenceUrl: url.isEmpty ? null : url,
  );
}
