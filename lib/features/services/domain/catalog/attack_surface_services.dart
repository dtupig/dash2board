import '../../../auth/domain/user_role.dart';
import '../delivery_model.dart';
import '../service_category.dart';
import '../service_offering.dart';

/// Categoria 3 - `attack_surface` (1 serviço).
/// Fonte: `docs/08_CATALOGO_SERVICOS.md`.
const List<ServiceOffering> attackSurfaceServices = <ServiceOffering>[
  ServiceOffering(
    serviceKey: 'asm_monitoring',
    category: ServiceCategory.attackSurface,
    label: 'Monitoramento de Superfície de Ataque',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.operational,
    shortPitch: 'Mostra continuamente tudo que a sua empresa expõe à internet, '
        'inclusive o que ninguém sabia que estava exposto.',
    typicalDurationDays: 30,
    requiresScopeAssets: true,
  ),
];
