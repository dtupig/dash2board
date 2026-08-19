import 'package:elytron_dash2board/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('aceita e-mails corporativos válidos', () {
      expect(Validators.email('daniel.tupinamba@elytronsecurity.com'), isNull);
      expect(Validators.email('  ciso@cliente.com.br  '), isNull);
    });

    test('rejeita entradas inválidas', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('sem-arroba'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('exige o mínimo do NIST SP 800-63B', () {
      expect(Validators.password('curta'), isNotNull);
      expect(Validators.password('senhaSuperLonga123'), isNull);
    });

    test('no login apenas a presença é exigida', () {
      expect(Validators.passwordPresence(''), isNotNull);
      expect(Validators.passwordPresence('x'), isNull);
    });
  });
}
