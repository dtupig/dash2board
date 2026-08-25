import 'package:elytron_dash2board/features/services/domain/service_catalog.dart';
import 'package:elytron_dash2board/features/services/domain/service_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('são exatamente 44 serviços', () {
    expect(ServiceCatalog.all.length, 44);
  });

  test('todas as serviceKey são únicas', () {
    final Set<String> keys =
        ServiceCatalog.all.map((s) => s.serviceKey).toSet();
    expect(keys.length, ServiceCatalog.all.length);
  });

  test('toda serviceKey pertence a uma das 8 categorias', () {
    for (final ServiceCategory category in ServiceCategory.values) {
      expect(ServiceCatalog.byCategory(category), isNotEmpty);
    }
    final int total = ServiceCategory.values
        .map((c) => ServiceCatalog.byCategory(c).length)
        .fold(0, (a, b) => a + b);
    expect(total, ServiceCatalog.all.length);
  });

  test('toda shortPitch é não vazia', () {
    for (final s in ServiceCatalog.all) {
      expect(s.shortPitch, isNotEmpty, reason: s.serviceKey);
    }
  });

  test('byKey encontra um serviço conhecido e devolve null para desconhecido',
      () {
    expect(ServiceCatalog.byKey('web_api')?.label, 'WEB Application - API');
    expect(ServiceCatalog.byKey('nao-existe'), isNull);
  });

  test('search ignora acento e maiúsculas/minúsculas', () {
    final List<String> byAccentedTerm =
        ServiceCatalog.search('PENETRAÇÃO').map((s) => s.serviceKey).toList();
    final List<String> byPlainTerm =
        ServiceCatalog.search('penetracao').map((s) => s.serviceKey).toList();
    expect(byAccentedTerm, isNotEmpty);
    expect(byAccentedTerm, byPlainTerm);
  });

  test('search por termo vazio devolve o catálogo inteiro', () {
    expect(ServiceCatalog.search('').length, ServiceCatalog.all.length);
  });
}
