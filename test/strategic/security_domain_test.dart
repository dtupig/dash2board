import 'package:elytron_dash2board/features/strategic/domain/security_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromWire reconhece os seis domínios de segurança', () {
    expect(SecurityDomain.fromWire('identity'), SecurityDomain.identity);
    expect(SecurityDomain.fromWire('endpoint'), SecurityDomain.endpoint);
    expect(SecurityDomain.fromWire('cloud'), SecurityDomain.cloud);
    expect(SecurityDomain.fromWire('appsec'), SecurityDomain.appsec);
    expect(SecurityDomain.fromWire('data'), SecurityDomain.data);
    expect(SecurityDomain.fromWire('thirdparty'), SecurityDomain.thirdParty);
  });

  test('fromWire desconhecido, nulo ou de tipo errado cai em fallback seguro',
      () {
    expect(SecurityDomain.fromWire('setor-novo'), SecurityDomain.identity);
    expect(SecurityDomain.fromWire(null), SecurityDomain.identity);
    expect(SecurityDomain.fromWire(42), SecurityDomain.identity);
  });

  test('todos os domínios têm rótulo em pt-BR preenchido', () {
    for (final SecurityDomain domain in SecurityDomain.values) {
      expect(domain.label, isNotEmpty);
    }
  });
}
