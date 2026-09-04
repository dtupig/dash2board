import '../../domain/compliance_control.dart';
import '../../domain/security_domain.dart';
import 'mock_strategic_compliance_common.dart';

List<ComplianceControl> buildComplianceControlsIsoNist(DateTime anchor) {
  ComplianceControl control({
    required ComplianceFramework framework,
    required String controlId,
    required String title,
    required ControlStatus status,
    required String ownerName,
    required int reviewedDaysAgo,
    required SecurityDomain domain,
  }) =>
      buildComplianceControl(
        anchor: anchor,
        framework: framework,
        controlId: controlId,
        title: title,
        status: status,
        ownerName: ownerName,
        reviewedDaysAgo: reviewedDaysAgo,
        domain: domain,
      );

  return <ComplianceControl>[
    // ISO 27001
    control(
      framework: ComplianceFramework.iso27001,
      controlId: 'A.5.1',
      title: 'Políticas de segurança da informação',
      status: ControlStatus.compliant,
      ownerName: 'Mariana Costa',
      reviewedDaysAgo: 20,
      domain: SecurityDomain.data,
    ),
    control(
      framework: ComplianceFramework.iso27001,
      controlId: 'A.8.1',
      title: 'Inventário de ativos de informação',
      status: ControlStatus.compliant,
      ownerName: 'Eduardo Lima',
      reviewedDaysAgo: 35,
      domain: SecurityDomain.endpoint,
    ),
    control(
      framework: ComplianceFramework.iso27001,
      controlId: 'A.9.2',
      title: 'Gestão de acesso de usuários',
      status: ControlStatus.partial,
      ownerName: 'Patrícia Alves',
      reviewedDaysAgo: 50,
      domain: SecurityDomain.identity,
    ),
    control(
      framework: ComplianceFramework.iso27001,
      controlId: 'A.12.6',
      title: 'Gestão de vulnerabilidades técnicas',
      status: ControlStatus.gap,
      ownerName: 'Fernando Rocha',
      reviewedDaysAgo: 65,
      domain: SecurityDomain.appsec,
    ),
    control(
      framework: ComplianceFramework.iso27001,
      controlId: 'A.16.1',
      title: 'Gestão de incidentes de segurança da informação',
      status: ControlStatus.compliant,
      ownerName: 'Juliana Prado',
      reviewedDaysAgo: 15,
      domain: SecurityDomain.endpoint,
    ),
    control(
      framework: ComplianceFramework.iso27001,
      controlId: 'A.5.23',
      title: 'Segurança da informação para uso de serviços em nuvem',
      status: ControlStatus.partial,
      ownerName: 'Rodrigo Teixeira',
      reviewedDaysAgo: 80,
      domain: SecurityDomain.cloud,
    ),
    // NIST CSF
    control(
      framework: ComplianceFramework.nistCsf,
      controlId: 'ID.AM-2',
      title: 'Inventário de plataformas e aplicações de software',
      status: ControlStatus.compliant,
      ownerName: 'Eduardo Lima',
      reviewedDaysAgo: 28,
      domain: SecurityDomain.endpoint,
    ),
    control(
      framework: ComplianceFramework.nistCsf,
      controlId: 'PR.AC-1',
      title: 'Identidades e credenciais gerenciadas para usuários',
      status: ControlStatus.compliant,
      ownerName: 'Mariana Costa',
      reviewedDaysAgo: 22,
      domain: SecurityDomain.identity,
    ),
    control(
      framework: ComplianceFramework.nistCsf,
      controlId: 'PR.DS-5',
      title: 'Proteção contra vazamento de dados',
      status: ControlStatus.partial,
      ownerName: 'Patrícia Alves',
      reviewedDaysAgo: 44,
      domain: SecurityDomain.data,
    ),
    control(
      framework: ComplianceFramework.nistCsf,
      controlId: 'DE.CM-8',
      title: 'Varredura contínua de vulnerabilidades',
      status: ControlStatus.gap,
      ownerName: 'Fernando Rocha',
      reviewedDaysAgo: 70,
      domain: SecurityDomain.appsec,
    ),
    control(
      framework: ComplianceFramework.nistCsf,
      controlId: 'RS.RP-1',
      title: 'Plano de resposta a incidentes executado',
      status: ControlStatus.compliant,
      ownerName: 'Juliana Prado',
      reviewedDaysAgo: 18,
      domain: SecurityDomain.endpoint,
    ),
    control(
      framework: ComplianceFramework.nistCsf,
      controlId: 'ID.SC-4',
      title: 'Fornecedores monitorados quanto ao risco introduzido',
      status: ControlStatus.gap,
      ownerName: 'Rodrigo Teixeira',
      reviewedDaysAgo: 90,
      domain: SecurityDomain.thirdParty,
    ),
  ];
}
