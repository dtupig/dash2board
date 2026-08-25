import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../auth/domain/user_role.dart';
import '../domain/contracted_service.dart';
import '../domain/service_request.dart';
import 'firestore_services_repository.dart';
import 'mock_services_repository.dart';
import 'services_repository.dart';

/// Repositório de dados do módulo de serviços - único ponto do app que sabe
/// se os dados vêm do mock ou do Firestore.
final Provider<ServicesRepository> servicesRepositoryProvider =
    Provider<ServicesRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockServicesRepository();
  }
  return FirestoreServicesRepository();
});

String? _watchTenantId(Ref ref) {
  final String? tenantId = ref.watch(appUserProvider).value?.tenantId;
  return (tenantId == null || tenantId.isEmpty) ? null : tenantId;
}

/// Serviços que o tenant do usuário logado efetivamente contratou.
final StreamProvider<List<ContractedService>> contractedServicesProvider =
    StreamProvider<List<ContractedService>>((ref) {
  final String? tenantId = _watchTenantId(ref);
  if (tenantId == null) {
    return Stream<List<ContractedService>>.value(const <ContractedService>[]);
  }
  return ref
      .watch(servicesRepositoryProvider)
      .watchContractedServices(tenantId);
});

/// Solicitações visíveis para o usuário logado, já filtradas pela alçada da
/// sua persona (todas para `strategic`, só as próprias para `operational`,
/// só fato relevante para `board`).
final StreamProvider<List<ServiceRequest>> serviceRequestsProvider =
    StreamProvider<List<ServiceRequest>>((ref) {
  final String? tenantId = _watchTenantId(ref);
  final UserRole? role = ref.watch(appUserProvider).value?.role;
  final String? uid = ref.watch(appUserProvider).value?.uid;
  if (tenantId == null || role == null) {
    return Stream<List<ServiceRequest>>.value(const <ServiceRequest>[]);
  }
  return ref.watch(servicesRepositoryProvider).watchRequests(
        tenantId: tenantId,
        roleWire: role.wireValue,
        requesterUid: uid,
      );
});

/// Uma solicitação específica, por id - usado pela tela de revisão do
/// wizard e pelo detalhe na fila de aprovação.
final serviceRequestProvider =
    StreamProvider.family<ServiceRequest?, String>((ref, requestId) {
  final String? tenantId = _watchTenantId(ref);
  if (tenantId == null) {
    return Stream<ServiceRequest?>.value(null);
  }
  return ref
      .watch(servicesRepositoryProvider)
      .watchRequest(tenantId, requestId);
});
