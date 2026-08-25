import '../domain/approval_record.dart';
import '../domain/contracted_service.dart';
import '../domain/request_driver.dart';
import '../domain/request_status.dart';
import '../domain/request_urgency.dart';
import '../domain/service_request.dart';

/// Identidade das contas de demonstração, reaproveitada de
/// `mock_auth_repository.dart` para que a narrativa do módulo de serviços
/// bata com quem está logado na demonstração.
abstract final class MockServiceActors {
  static const String opUid = 'demo-operational';
  static const String opName = 'Rafael Moura';
  static const String cisoUid = 'demo-strategic';
  static const String cisoName = 'Ana Ribeiro';
}

/// 9 serviços contratados pelo tenant de demonstração, em 6 categorias -
/// dados fixos e reproduzíveis, ancorados em [anchor].
List<ContractedService> mockContractedServices(DateTime anchor) {
  DateTime daysBefore(int days) => anchor.subtract(Duration(days: days));
  DateTime daysAfter(int days) => anchor.add(Duration(days: days));

  ContractedService contract(
    String serviceKey,
    String contractId,
    int startedDaysAgo,
    int endsInDays, {
    required bool active,
    required int delivered,
  }) {
    return ContractedService(
      serviceKey: serviceKey,
      contractId: contractId,
      startedAt: daysBefore(startedDaysAgo),
      endsAt: daysAfter(endsInDays),
      status: active ? ContractStatus.active : ContractStatus.expiring,
      lastDeliveryAt: daysBefore(5),
      deliveriesCount: delivered,
    );
  }

  return <ContractedService>[
    contract('web_api', 'ctr-001', 300, 65, active: true, delivered: 20),
    contract('infrastructure', 'ctr-002', 200, 165,
        active: true, delivered: 10),
    contract('dast', 'ctr-003', 400, 500, active: true, delivered: 40),
    contract('sast', 'ctr-004', 400, 500, active: true, delivered: 55),
    contract('asm_monitoring', 'ctr-005', 180, 185, active: true, delivered: 6),
    contract(
      'vulnerability_management',
      'ctr-006',
      365,
      400,
      active: true,
      delivered: 12,
    ),
    contract(
      'threat_intelligence',
      'ctr-007',
      300,
      20,
      active: false,
      delivered: 8,
    ),
    contract('edr_xdr_ndr', 'ctr-008', 250, 300, active: true, delivered: 15),
    contract(
      'third_party_management',
      'ctr-009',
      200,
      25,
      active: false,
      delivered: 4,
    ),
  ];
}

/// 6 solicitações em estados diferentes - uma rejeitada com nota, uma em
/// `proposalReceived`, uma `crisis` - dados fixos e reproduzíveis, ancorados
/// em [anchor].
List<ServiceRequest> mockServiceRequests(DateTime anchor) {
  DateTime daysBefore(int days) => anchor.subtract(Duration(days: days));
  DateTime daysAfter(int days) => anchor.add(Duration(days: days));

  ServiceRequest request({
    required String id,
    required String serviceKey,
    required String uid,
    required String name,
    required RequestUrgency urgency,
    required RequestDriver driver,
    required String scopeSummary,
    required List<String> scopeAssets,
    required String justification,
    required int windowDaysAhead,
    required RequestStatus status,
    ApprovalRecord? approval,
  }) {
    return ServiceRequest(
      id: id,
      tenantId: 'tenant-demo',
      serviceKey: serviceKey,
      requestedByUid: uid,
      requestedByName: name,
      createdAt: daysBefore(10),
      urgency: urgency,
      driver: driver,
      scopeSummary: scopeSummary,
      scopeAssets: scopeAssets,
      businessJustification: justification,
      desiredWindow: daysAfter(windowDaysAhead),
      status: status,
      approval: approval,
      timeline: <RequestTimelineEvent>[
        RequestTimelineEvent(
          status: RequestStatus.draft,
          occurredAt: daysBefore(10),
        ),
        RequestTimelineEvent(status: status, occurredAt: daysBefore(2)),
      ],
    );
  }

  const String opUid = MockServiceActors.opUid;
  const String opName = MockServiceActors.opName;
  const String cisoUid = MockServiceActors.cisoUid;
  const String cisoName = MockServiceActors.cisoName;

  return <ServiceRequest>[
    request(
      id: 'req-001',
      serviceKey: 'reverse_engineering',
      uid: opUid,
      name: opName,
      urgency: RequestUrgency.planned,
      driver: RequestDriver.newProject,
      scopeSummary: 'Novo aplicativo desktop antes do lançamento.',
      scopeAssets: const <String>['instalador-windows-v3.exe'],
      justification:
          'Produto novo com dado de cliente embarcado - precisa de validação '
          'antes de ir ao mercado.',
      windowDaysAhead: 45,
      status: RequestStatus.draft,
    ),
    request(
      id: 'req-002',
      serviceKey: 'digital_investigation',
      uid: opUid,
      name: opName,
      urgency: RequestUrgency.crisis,
      driver: RequestDriver.incident,
      scopeSummary: 'Possível exfiltração de dado por ex-funcionário.',
      scopeAssets: const <String>['notebook-corporativo-BR-4521'],
      justification:
          'Indício de cópia de base de clientes antes do desligamento - '
          'precisa de perícia para eventual ação judicial.',
      windowDaysAhead: 2,
      status: RequestStatus.pendingApproval,
    ),
    request(
      id: 'req-003',
      serviceKey: 'threat_hunting',
      uid: cisoUid,
      name: cisoName,
      urgency: RequestUrgency.urgent,
      driver: RequestDriver.auditFinding,
      scopeSummary: 'Auditoria externa recomendou caça ativa a ameaças.',
      scopeAssets: const <String>['ambiente-produção-aws'],
      justification:
          'Achado de auditoria de segurança do último trimestre - resposta '
          'exigida no plano de ação.',
      windowDaysAhead: 20,
      status: RequestStatus.approved,
      approval: ApprovalRecord(
        decidedByUid: cisoUid,
        decidedByName: cisoName,
        decidedAt: daysBefore(2),
        decision: ApprovalDecision.approved,
        isSelfApproval: true,
      ),
    ),
    request(
      id: 'req-004',
      serviceKey: 'waf_waap',
      uid: cisoUid,
      name: cisoName,
      urgency: RequestUrgency.nextQuarter,
      driver: RequestDriver.newProject,
      scopeSummary: 'Nova API pública de pagamentos.',
      scopeAssets: const <String>['api.pagamentos.tenant-demo.com'],
      justification: 'API pública nova precisa de proteção antes do lançamento '
          'comercial no próximo trimestre.',
      windowDaysAhead: 75,
      status: RequestStatus.sentToElytron,
      approval: ApprovalRecord(
        decidedByUid: cisoUid,
        decidedByName: cisoName,
        decidedAt: daysBefore(3),
        decision: ApprovalDecision.approved,
        isSelfApproval: true,
      ),
    ),
    request(
      id: 'req-005',
      serviceKey: 'mobile',
      uid: opUid,
      name: opName,
      urgency: RequestUrgency.planned,
      driver: RequestDriver.clientDemand,
      scopeSummary: 'Cliente estratégico exigiu laudo de pentest mobile.',
      scopeAssets: const <String>['app iOS v5.2', 'app Android v5.2'],
      justification:
          'Condição contratual de um cliente estratégico para renovação '
          'do contrato principal.',
      windowDaysAhead: 30,
      status: RequestStatus.proposalReceived,
      approval: ApprovalRecord(
        decidedByUid: cisoUid,
        decidedByName: cisoName,
        decidedAt: daysBefore(6),
        decision: ApprovalDecision.approved,
      ),
    ),
    request(
      id: 'req-006',
      serviceKey: 'phishing_workshop',
      uid: opUid,
      name: opName,
      urgency: RequestUrgency.planned,
      driver: RequestDriver.internalInitiative,
      scopeSummary: 'Reforço de conscientização depois de um quase-incidente.',
      scopeAssets: const <String>[],
      justification:
          'Um analista quase clicou em phishing direcionado mês passado - '
          'quer treinar toda a área comercial.',
      windowDaysAhead: 40,
      status: RequestStatus.rejected,
      approval: ApprovalRecord(
        decidedByUid: cisoUid,
        decidedByName: cisoName,
        decidedAt: daysBefore(1),
        decision: ApprovalDecision.rejected,
        note: 'Orçamento do trimestre já alocado - reavaliar no próximo ciclo '
            'orçamentário.',
      ),
    ),
  ];
}
