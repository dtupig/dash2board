import 'catalog/appsec_services.dart';
import 'catalog/attack_surface_services.dart';
import 'catalog/defense_services.dart';
import 'catalog/governance_services.dart';
import 'catalog/pentest_services.dart';
import 'catalog/response_services.dart';
import 'catalog/third_party_services.dart';
import 'catalog/vulnerability_services.dart';
import 'service_category.dart';
import 'service_offering.dart';

/// Fonte única de verdade dos 44 serviços vendidos pela Elytron.
///
/// Os dados propriamente ditos ficam divididos por categoria em
/// `catalog/*_services.dart` (mantém cada arquivo abaixo do limite de 250
/// linhas do projeto); esta classe só agrega e oferece os utilitários que o
/// catálogo e o wizard precisam.
abstract final class ServiceCatalog {
  static const List<ServiceOffering> all = <ServiceOffering>[
    ...pentestServices,
    ...appsecServices,
    ...attackSurfaceServices,
    ...responseServices,
    ...governanceServices,
    ...vulnerabilityServices,
    ...thirdPartyServices,
    ...defenseServices,
  ];

  /// Serviços de uma categoria, na ordem em que aparecem no catálogo fonte.
  static List<ServiceOffering> byCategory(ServiceCategory category) {
    return all
        .where((ServiceOffering s) => s.category == category)
        .toList(growable: false);
  }

  /// `null` quando a chave não existe - nunca inventa um serviço vazio.
  static ServiceOffering? byKey(String serviceKey) {
    for (final ServiceOffering offering in all) {
      if (offering.serviceKey == serviceKey) {
        return offering;
      }
    }
    return null;
  }

  /// Busca por rótulo, sem diferenciar maiúsculas/minúsculas e sem acento.
  static List<ServiceOffering> search(String term) {
    final String needle = _normalize(term);
    if (needle.isEmpty) {
      return all;
    }
    return all
        .where((ServiceOffering s) =>
            _normalize(s.label).contains(needle) ||
            _normalize(s.category.label).contains(needle))
        .toList(growable: false);
  }

  static const Map<String, String> _accentedToPlain = <String, String>{
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'õ': 'o',
    'ô': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  static String _normalize(String value) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in value.toLowerCase().runes) {
      final String char = String.fromCharCode(rune);
      buffer.write(_accentedToPlain[char] ?? char);
    }
    return buffer.toString();
  }
}
