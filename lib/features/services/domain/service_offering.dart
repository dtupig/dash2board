import '../../auth/domain/user_role.dart';
import 'delivery_model.dart';
import 'service_category.dart';

/// Um dos 44 serviços do catálogo Elytron - a unidade que o cliente pode
/// contratar ou demandar.
///
/// É um valor imutável e conhecido em tempo de compilação (ver
/// `service_catalog.dart`): não existe leitura de rede para saber o que a
/// Elytron vende, só para saber o que ESTE tenant já contratou
/// ([ContractedService]).
class ServiceOffering {
  const ServiceOffering({
    required this.serviceKey,
    required this.category,
    required this.label,
    required this.deliveryModel,
    required this.primaryPersona,
    required this.shortPitch,
    required this.typicalDurationDays,
    required this.requiresScopeAssets,
  });

  /// Chave estável e `snake_case`, nunca reutilizada nem renomeada depois de
  /// publicada - vai para o Firestore e para relatórios já emitidos.
  final String serviceKey;

  final ServiceCategory category;
  final String label;
  final DeliveryModel deliveryModel;

  /// Persona que tipicamente demanda e consome este serviço.
  final UserRole primaryPersona;

  /// Uma frase, em linguagem de negócio, do que o cliente ganha - nunca do
  /// que a Elytron faz. Aparece no cartão do catálogo.
  final String shortPitch;

  final int typicalDurationDays;

  /// Quando verdadeiro, o wizard de demanda pede a lista de alvos (domínios,
  /// aplicações, repositórios, faixas de IP, contas de nuvem) no passo de
  /// escopo. Quando falso, pede volume/abrangência em vez de alvos.
  final bool requiresScopeAssets;

  @override
  bool operator ==(Object other) =>
      other is ServiceOffering && other.serviceKey == serviceKey;

  @override
  int get hashCode => serviceKey.hashCode;

  @override
  String toString() => 'ServiceOffering($serviceKey)';
}
