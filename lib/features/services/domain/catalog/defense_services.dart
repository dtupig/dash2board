import '../../../auth/domain/user_role.dart';
import '../delivery_model.dart';
import '../service_category.dart';
import '../service_offering.dart';

/// Categoria 8 - `defense` (10 serviços). Fonte:
/// `docs/08_CATALOGO_SERVICOS.md`.
const List<ServiceOffering> defenseServices = <ServiceOffering>[
  ServiceOffering(
    serviceKey: 'cloud_posture',
    category: ServiceCategory.defense,
    label: 'Cloud Posture (Google, M365, Azure)',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.operational,
    shortPitch: 'Verifica continuamente se as suas contas de nuvem estão '
        'configuradas com segurança, não só no dia da migração.',
    typicalDurationDays: 30,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'deep_dark_web',
    category: ServiceCategory.defense,
    label: 'Monitoramento na Deep e Dark Web',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.strategic,
    shortPitch:
        'Avisa quando a marca, um executivo ou um dado da empresa aparece '
        'sendo negociado onde a lei não alcança.',
    typicalDurationDays: 180,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'threat_intelligence',
    category: ServiceCategory.defense,
    label: 'Threat Intelligence e CTI',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.strategic,
    shortPitch:
        'Antecipa a ameaça relevante para o seu setor, em vez de reagir '
        'depois que ela já bateu na porta.',
    typicalDurationDays: 180,
    requiresScopeAssets: false,
  ),
  ServiceOffering(
    serviceKey: 'threat_hunting',
    category: ServiceCategory.defense,
    label: 'Threat Hunting',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Caça ativamente o invasor que já pode estar dentro do ambiente, sem '
        'esperar o alarme disparar.',
    typicalDurationDays: 30,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'implementation_tuning',
    category: ServiceCategory.defense,
    label: 'Implementação / Evolução (fine tuning)',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Ajusta a ferramenta de segurança que você já tem para parar de '
        'gerar ruído e passar a proteger de verdade.',
    typicalDurationDays: 20,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'email_protection',
    category: ServiceCategory.defense,
    label: 'E-mail Protection',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Bloqueia phishing e fraude por e-mail antes que cheguem à caixa de '
        'entrada de alguém desatento.',
    typicalDurationDays: 90,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'edr_xdr_ndr',
    category: ServiceCategory.defense,
    label: 'EDR / XDR / NDR',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Detecta e responde a ataques em endpoint e rede em tempo real, com '
        'um time observando 24 horas.',
    typicalDurationDays: 90,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'microsegmentation',
    category: ServiceCategory.defense,
    label: 'Microsegmentação',
    deliveryModel: DeliveryModel.oneOff,
    primaryPersona: UserRole.operational,
    shortPitch:
        'Isola partes da rede para que um invasor que entre por um lado não '
        'chegue a todo o resto.',
    typicalDurationDays: 30,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'waf_waap',
    category: ServiceCategory.defense,
    label: 'WAF / WAAP - API Protection',
    deliveryModel: DeliveryModel.continuous,
    primaryPersona: UserRole.operational,
    shortPitch: 'Protege sites e APIs contra ataque automatizado antes que ele '
        'chegue à aplicação.',
    typicalDurationDays: 90,
    requiresScopeAssets: true,
  ),
  ServiceOffering(
    serviceKey: 'phishing_workshop',
    category: ServiceCategory.defense,
    label: 'Phishing e Workshop',
    deliveryModel: DeliveryModel.recurring,
    primaryPersona: UserRole.strategic,
    shortPitch: 'Testa e treina os funcionários contra phishing com simulações '
        'reais, medindo a evolução ao longo do tempo.',
    typicalDurationDays: 5,
    requiresScopeAssets: false,
  ),
];
