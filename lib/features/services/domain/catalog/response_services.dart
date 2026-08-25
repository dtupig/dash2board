import '../../../auth/domain/user_role.dart';
import '../delivery_model.dart';
import '../service_category.dart';
import '../service_offering.dart';

/// Categoria 4 - `response` (12 serviços). Fonte:
/// `docs/08_CATALOGO_SERVICOS.md`.
const List<ServiceOffering> responseServices = <ServiceOffering>[
  ServiceOffering(
    serviceKey: 'dfir_retainer',
    category: ServiceCategory.response,
    label: 'RETAINER DFIR: Resposta a Incidente',
    deliveryModel: DeliveryModel.retainer,
    primaryPersona: UserRole.strategic,
    shortPitch: 'Garante um time de resposta a incidente pronto para agir, sem '
        'precisar negociar contrato no meio da crise.',
    typicalDurationDays: 365,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'digital_investigation',
    category: ServiceCategory.response,
    label: 'Investigações Digitais e Perícia Forense',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.strategic,
    shortPitch:
        'Reconstrói o que aconteceu, com rigor pericial suficiente para '
        'sustentar uma decisão jurídica ou disciplinar.',
    typicalDurationDays: 30,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'tabletop',
    category: ServiceCategory.response,
    label: 'Tabletop Exercise',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.strategic,
    shortPitch:
        'Testa, em uma sala e sem risco real, se o seu plano de resposta a '
        'incidente realmente funciona.',
    typicalDurationDays: 5,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'wargame_ctf',
    category: ServiceCategory.response,
    label: 'Wargame / GCC / Capture the Flag (CTF)',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.operational,
    shortPitch: 'Treina o time técnico em um exercício competitivo de ataque e '
        'defesa, num ambiente controlado.',
    typicalDurationDays: 2,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'crisis_simulation',
    category: ServiceCategory.response,
    label: 'Simulação de Crise Cibernética',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.board,
    shortPitch:
        'Coloca a liderança executiva para decidir, ao vivo, como a empresa '
        'reagiria a um ataque cibernético grave.',
    typicalDurationDays: 1,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'forensics_mobile',
    category: ServiceCategory.response,
    label: 'Forense Digital: Coleta de celular',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.operational,
    shortPitch: 'Extrai e preserva a evidência de um celular com a cadeia de '
        'custódia que um caso jurídico exige.',
    typicalDurationDays: 5,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'forensics_endpoint',
    category: ServiceCategory.response,
    label: 'Forense Digital: Coleta de endpoint',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Extrai e preserva a evidência de um computador ou servidor com '
        'cadeia de custódia íntegra.',
    typicalDurationDays: 5,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'forensics_cloud',
    category: ServiceCategory.response,
    label: 'Forense Digital: Coleta em nuvem',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Extrai e preserva evidência de um ambiente de nuvem, respeitando as '
        'particularidades de cada provedor.',
    typicalDurationDays: 7,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'forensics_remote',
    category: ServiceCategory.response,
    label: 'Forense Digital: Coleta remota',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Coleta evidência forense sem precisar de ninguém fisicamente no '
        'local, sem perder rigor pericial.',
    typicalDurationDays: 5,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'forensics_processing',
    category: ServiceCategory.response,
    label: 'Forense Digital: Processamento de dados',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Transforma a evidência já coletada em achados legíveis, com linha '
        'do tempo e artefatos organizados.',
    typicalDurationDays: 10,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'forensics_hosting_hash',
    category: ServiceCategory.response,
    label: 'Forense Digital: Hosting com HASH',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Guarda a evidência coletada em cofre íntegro e auditável, pronta '
        'para quando for pedida.',
    typicalDurationDays: 365,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'forensics_uam',
    category: ServiceCategory.response,
    label: 'Forense Digital: UAM (User Activity Monitoring)',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.strategic,
    shortPitch:
        'Monitora a atividade de usuários de risco de forma contínua, com '
        'base legal documentada.',
    typicalDurationDays: 180,
    requiresScopeAssets: false,
  ),
];
