import '../../auth/domain/user_role.dart';
import '../domain/approval_record.dart';
import '../domain/contracted_service.dart';
import '../domain/request_driver.dart';
import '../domain/request_policy.dart';
import '../domain/request_status.dart';
import '../domain/request_urgency.dart';
import '../domain/service_request.dart';
import 'mock_services_data.dart';
import 'services_repository.dart';

/// Dados de demonstração do módulo de serviços, 100% em memória.
///
/// Reaproveita a identidade das contas de demonstração e a mesma data de
/// referência fixa das outras demonstrações do app
/// (`MockStrategicRepository._anchor`), para que a narrativa seja
/// **reproduzível**. Os dados fixos (9 serviços contratados, 6 solicitações)
/// vivem em `mock_services_data.dart`, para manter este arquivo abaixo do
/// limite de 250 linhas.
class MockServicesRepository implements ServicesRepository {
  static const Duration _streamDelay = Duration(milliseconds: 400);
  static final DateTime _anchor = DateTime.utc(2026, 8, 1);

  int _requestCounter = 0;

  late final List<ServiceRequest> _requests = mockServiceRequests(_anchor);
  late final List<ContractedService> _contracted =
      mockContractedServices(_anchor);

  @override
  Stream<List<ContractedService>> watchContractedServices(String tenantId) {
    return _afterDelay(() => List<ContractedService>.of(_contracted));
  }

  @override
  Stream<List<ServiceRequest>> watchRequests({
    required String tenantId,
    required String roleWire,
    String? requesterUid,
  }) {
    return _afterDelay(() {
      if (roleWire == 'operational') {
        return _requests
            .where((ServiceRequest r) => r.requestedByUid == requesterUid)
            .toList(growable: false);
      }
      if (roleWire == 'board') {
        // Sem mecanismo de fato relevante ainda (prompt 11) - até lá, o
        // board não vê nenhuma solicitação, só o aviso de que é informado
        // por exceção.
        return const <ServiceRequest>[];
      }
      return List<ServiceRequest>.of(_requests);
    });
  }

  @override
  Stream<ServiceRequest?> watchRequest(String tenantId, String requestId) {
    return _afterDelay(() {
      for (final ServiceRequest request in _requests) {
        if (request.id == requestId) {
          return request;
        }
      }
      return null;
    });
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
    await Future<void>.delayed(_streamDelay);
    final String id = 'req-mock-${_requestCounter++}';
    final bool selfApproves =
        !RequestPolicy.requiresApproval(UserRole.fromWire(openerRoleWire));
    final RequestStatus status =
        selfApproves ? RequestStatus.approved : RequestStatus.pendingApproval;
    final ApprovalRecord? approval = selfApproves
        ? ApprovalRecord(
            decidedByUid: requestedByUid,
            decidedByName: requestedByName,
            decidedAt: _anchor,
            decision: ApprovalDecision.approved,
            isSelfApproval: true,
          )
        : null;
    _requests.add(
      ServiceRequest(
        id: id,
        tenantId: tenantId,
        serviceKey: serviceKey,
        requestedByUid: requestedByUid,
        requestedByName: requestedByName,
        createdAt: _anchor,
        urgency: urgency,
        driver: driver,
        scopeSummary: scopeSummary,
        scopeAssets: scopeAssets,
        businessJustification: businessJustification,
        desiredWindow: desiredWindow,
        status: status,
        approval: approval,
        timeline: <RequestTimelineEvent>[
          RequestTimelineEvent(
              status: RequestStatus.draft, occurredAt: _anchor),
          RequestTimelineEvent(status: status, occurredAt: _anchor),
        ],
      ),
    );
    return id;
  }

  @override
  Future<void> submitForApproval(String tenantId, String requestId) async {
    await Future<void>.delayed(_streamDelay);
    final int index =
        _requests.indexWhere((ServiceRequest r) => r.id == requestId);
    if (index == -1) {
      return;
    }
    final ServiceRequest current = _requests[index];
    current.status.canTransitionTo(RequestStatus.pendingApproval);
    _requests[index] = current.copyWith(
      status: RequestStatus.pendingApproval,
      timeline: <RequestTimelineEvent>[
        ...current.timeline,
        RequestTimelineEvent(
          status: RequestStatus.pendingApproval,
          occurredAt: _anchor,
        ),
      ],
    );
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
    await Future<void>.delayed(_streamDelay);
    final int index =
        _requests.indexWhere((ServiceRequest r) => r.id == requestId);
    if (index == -1) {
      return;
    }
    final ServiceRequest current = _requests[index];
    final RequestStatus next = decision == ApprovalDecision.approved
        ? RequestStatus.approved
        : RequestStatus.rejected;
    current.status.canTransitionTo(next);
    _requests[index] = current.copyWith(
      status: next,
      approval: ApprovalRecord(
        decidedByUid: decidedByUid,
        decidedByName: decidedByName,
        decidedAt: _anchor,
        decision: decision,
        note: note,
      ),
      timeline: <RequestTimelineEvent>[
        ...current.timeline,
        RequestTimelineEvent(status: next, occurredAt: _anchor, note: note),
      ],
    );
  }

  @override
  Future<void> cancelRequest(String tenantId, String requestId) async {
    await Future<void>.delayed(_streamDelay);
    final int index =
        _requests.indexWhere((ServiceRequest r) => r.id == requestId);
    if (index == -1) {
      return;
    }
    final ServiceRequest current = _requests[index];
    current.status.canTransitionTo(RequestStatus.cancelled);
    _requests[index] = current.copyWith(
      status: RequestStatus.cancelled,
      timeline: <RequestTimelineEvent>[
        ...current.timeline,
        RequestTimelineEvent(
          status: RequestStatus.cancelled,
          occurredAt: _anchor,
        ),
      ],
    );
  }

  Stream<T> _afterDelay<T>(T Function() compute) async* {
    await Future<void>.delayed(_streamDelay);
    yield compute();
  }
}
