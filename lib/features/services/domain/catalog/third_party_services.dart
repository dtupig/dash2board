import '../../../auth/domain/user_role.dart';
import '../delivery_model.dart';
import '../service_category.dart';
import '../service_offering.dart';

/// Categoria 7 - `third_party` (1 serviço). Fonte:
/// `docs/08_CATALOGO_SERVICOS.md`.
const List<ServiceOffering> thirdPartyServices = <ServiceOffering>[
  ServiceOffering(
    serviceKey: 'third_party_management',
    category: ServiceCategory.thirdParty,
    label: 'Gestão de Terceiros',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.strategic,
    shortPitch:
        'Acompanha continuamente o risco que cada fornecedor introduz no seu '
        'negócio, não só no dia da contratação.',
    typicalDurationDays: 90,
    requiresScopeAssets: false,
  ),
];
