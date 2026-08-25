import '../domain/approval_record.dart';
import '../domain/contracted_service.dart';
import '../domain/request_driver.dart';
import '../domain/request_urgency.dart';
import '../domain/service_request.dart';

/// Contrato de dados do módulo de serviços (catálogo, contratação e RFS).
///
/// Duas implementações, escolhidas uma única vez em `services_providers.dart`:
/// [MockServicesRepository] (demonstração offline) e
/// [FirestoreServicesRepository] (produção).
abstract interface class ServicesRepository {
  /// Serviços que o tenant efetivamente contratou.
  Stream<List<ContractedService>> watchContractedServices(String tenantId);

  /// Solicitações visíveis para [role]: todas para `strategic`, só as
  /// próprias para `operational` (por isso [requesterUid]), e só as
  /// marcadas como fato relevante para `board` (filtro aplicado pela
  /// implementação, espelhando `firestore.rules`).
  Stream<List<ServiceRequest>> watchRequests({
    required String tenantId,
    required String roleWire,
    String? requesterUid,
  });

  Stream<ServiceRequest?> watchRequest(String tenantId, String requestId);

  /// Cria uma nova solicitação. Quando [openerRoleWire] é `strategic`, a
  /// solicitação já nasce em `approved`, com um [ApprovalRecord]
  /// `isSelfApproval: true` - a auditoria não aceita um buraco de "quem
  /// aprovou" só porque quem aprovou também é quem abriu
  /// (`RequestPolicy.requiresApproval`).
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
  });

  /// Move a solicitação de `draft` para `pendingApproval` (ou `sentToElytron`
  /// quando já vem auto-aprovada) - ponto único de envio do wizard.
  Future<void> submitForApproval(String tenantId, String requestId);

  /// Registra a decisão do CISO. Rejeitar sem [note] é impossível: o domínio
  /// falha antes de chegar à camada de dados.
  Future<void> decideApproval({
    required String tenantId,
    required String requestId,
    required ApprovalDecision decision,
    required String decidedByUid,
    required String decidedByName,
    required String note,
  });

  Future<void> cancelRequest(String tenantId, String requestId);
}
