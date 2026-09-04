import '../../domain/compliance_control.dart';
import '../../domain/security_domain.dart';
import 'mock_strategic_compliance_common.dart';

List<ComplianceControl> buildComplianceControlsLgpdPci(DateTime anchor) {
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
    // LGPD
    control(
      framework: ComplianceFramework.lgpd,
      controlId: 'Art.6',
      title: 'Princípios do tratamento de dados pessoais observados',
      status: ControlStatus.compliant,
      ownerName: 'Patrícia Alves',
      reviewedDaysAgo: 30,
      domain: SecurityDomain.data,
    ),
    control(
      framework: ComplianceFramework.lgpd,
      controlId: 'Art.46',
      title: 'Medidas de segurança técnicas e administrativas',
      status: ControlStatus.compliant,
      ownerName: 'Mariana Costa',
      reviewedDaysAgo: 25,
      domain: SecurityDomain.data,
    ),
    control(
      framework: ComplianceFramework.lgpd,
      controlId: 'Art.48',
      title: 'Comunicação de incidente de segurança à ANPD',
      status: ControlStatus.partial,
      ownerName: 'Fernando Rocha',
      reviewedDaysAgo: 55,
      domain: SecurityDomain.endpoint,
    ),
    control(
      framework: ComplianceFramework.lgpd,
      controlId: 'Art.37',
      title: 'Registro das operações de tratamento de dados',
      status: ControlStatus.compliant,
      ownerName: 'Juliana Prado',
      reviewedDaysAgo: 40,
      domain: SecurityDomain.data,
    ),
    control(
      framework: ComplianceFramework.lgpd,
      controlId: 'Art.41',
      title: 'Encarregado de proteção de dados (DPO) formalizado',
      status: ControlStatus.compliant,
      ownerName: 'Eduardo Lima',
      reviewedDaysAgo: 60,
      domain: SecurityDomain.data,
    ),
    control(
      framework: ComplianceFramework.lgpd,
      controlId: 'Art.39',
      title: 'Contratos com operadores de dados revisados',
      status: ControlStatus.partial,
      ownerName: 'Rodrigo Teixeira',
      reviewedDaysAgo: 75,
      domain: SecurityDomain.thirdParty,
    ),
    // PCI DSS
    control(
      framework: ComplianceFramework.pciDss,
      controlId: 'Req.1',
      title: 'Firewall e segmentação de rede',
      status: ControlStatus.compliant,
      ownerName: 'Fernando Rocha',
      reviewedDaysAgo: 33,
      domain: SecurityDomain.cloud,
    ),
    control(
      framework: ComplianceFramework.pciDss,
      controlId: 'Req.3',
      title: 'Proteção de dados de titulares de cartão armazenados',
      status: ControlStatus.compliant,
      ownerName: 'Mariana Costa',
      reviewedDaysAgo: 27,
      domain: SecurityDomain.data,
    ),
    control(
      framework: ComplianceFramework.pciDss,
      controlId: 'Req.6',
      title: 'Desenvolvimento seguro de aplicações',
      status: ControlStatus.gap,
      ownerName: 'Patrícia Alves',
      reviewedDaysAgo: 85,
      domain: SecurityDomain.appsec,
    ),
    control(
      framework: ComplianceFramework.pciDss,
      controlId: 'Req.8',
      title: 'Identificação e autenticação de acesso',
      status: ControlStatus.compliant,
      ownerName: 'Juliana Prado',
      reviewedDaysAgo: 19,
      domain: SecurityDomain.identity,
    ),
    control(
      framework: ComplianceFramework.pciDss,
      controlId: 'Req.10',
      title: 'Rastreamento e monitoramento de todos os acessos',
      status: ControlStatus.partial,
      ownerName: 'Eduardo Lima',
      reviewedDaysAgo: 48,
      domain: SecurityDomain.identity,
    ),
    control(
      framework: ComplianceFramework.pciDss,
      controlId: 'Req.12',
      title: 'Avaliação de risco de fornecedores terceirizados',
      status: ControlStatus.gap,
      ownerName: 'Rodrigo Teixeira',
      reviewedDaysAgo: 95,
      domain: SecurityDomain.thirdParty,
    ),
  ];
}
