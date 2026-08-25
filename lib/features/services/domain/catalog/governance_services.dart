import '../../../auth/domain/user_role.dart';
import '../delivery_model.dart';
import '../service_category.dart';
import '../service_offering.dart';

/// Categoria 5 - `governance` (5 serviços). Fonte:
/// `docs/08_CATALOGO_SERVICOS.md`.
const List<ServiceOffering> governanceServices = <ServiceOffering>[
  ServiceOffering(
    serviceKey: 'regulatory_consulting',
    category: ServiceCategory.governance,
    label: 'Consultoria DORA, NIST, PCI, LGPD, GDPR',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.strategic,
    shortPitch: 'Traduz a exigência regulatória em um plano de adequação que a '
        'empresa consegue de fato executar.',
    typicalDurationDays: 30,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'bcp_assessment',
    category: ServiceCategory.governance,
    label: 'Assessments de Plano de Continuidade',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.strategic,
    shortPitch: 'Avalia se a empresa realmente voltaria a operar depois de uma '
        'interrupção grave, e em quanto tempo.',
    typicalDurationDays: 20,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'master_plan_policies',
    category: ServiceCategory.governance,
    label: 'Planos Diretores e Políticas',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.strategic,
    shortPitch:
        'Constrói o plano diretor de segurança e as políticas que faltavam '
        'para dar direção ao programa.',
    typicalDurationDays: 30,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'disaster_recovery',
    category: ServiceCategory.governance,
    label: 'Disaster Recovery',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.strategic,
    shortPitch:
        'Desenha e testa o plano de recuperação de desastre dos sistemas '
        'críticos do negócio.',
    typicalDurationDays: 25,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'maturity_assessment',
    category: ServiceCategory.governance,
    label: 'Assessments de Maturidade',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.board,
    shortPitch:
        'Mede, com um número comparável ao do mercado, o quanto o programa '
        'de segurança já amadureceu.',
    typicalDurationDays: 15,
    requiresScopeAssets: false,
  ),
];
