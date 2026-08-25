import '../../../auth/domain/user_role.dart';
import '../delivery_model.dart';
import '../service_category.dart';
import '../service_offering.dart';

/// Categoria 2 - `appsec` (7 serviços). Fonte: `docs/08_CATALOGO_SERVICOS.md`.
const List<ServiceOffering> appsecServices = <ServiceOffering>[
  ServiceOffering(
    serviceKey: 'secure_dev_training',
    category: ServiceCategory.appsec,
    label: 'Treinamento de desenvolvimento seguro',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.strategic,
    shortPitch:
        'Ensina o time de desenvolvimento a não criar a falha, em vez de só '
        'corrigi-la depois de pronta.',
    typicalDurationDays: 5,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'secure_dev_support',
    category: ServiceCategory.appsec,
    label: 'Apoio de desenvolvimento seguro',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.operational,
    shortPitch: 'Coloca um especialista de segurança junto do seu time de '
        'desenvolvimento no dia a dia.',
    typicalDurationDays: 180,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'dast',
    category: ServiceCategory.appsec,
    label: 'DAST',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.operational,
    shortPitch: 'Varre a aplicação em produção continuamente, do jeito que um '
        'visitante externo a enxerga.',
    typicalDurationDays: 30,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'sast',
    category: ServiceCategory.appsec,
    label: 'SAST',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Analisa o código-fonte a cada mudança, achando a falha antes dela '
        'chegar ao ar.',
    typicalDurationDays: 30,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'manual_review',
    category: ServiceCategory.appsec,
    label: 'Manual (Especialista)',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.operational,
    shortPitch: 'Um especialista examina o que a ferramenta automática não '
        'enxerga: lógica de negócio e falhas de desenho.',
    typicalDurationDays: 10,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'policy_development',
    category: ServiceCategory.appsec,
    label: 'Desenvolvimento de política',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.strategic,
    shortPitch: 'Escreve a política de desenvolvimento seguro que faltava para '
        'auditoria e certificação.',
    typicalDurationDays: 20,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'security_champion',
    category: ServiceCategory.appsec,
    label: 'Security Champion',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.strategic,
    shortPitch:
        'Forma multiplicadores de segurança dentro dos próprios times de '
        'desenvolvimento, com acompanhamento contínuo.',
    typicalDurationDays: 180,
    requiresScopeAssets: false,
  ),
];
