import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole.fromWire', () {
    test('reconhece as três personas do produto', () {
      expect(UserRole.fromWire('operational'), UserRole.operational);
      expect(UserRole.fromWire('strategic'), UserRole.strategic);
      expect(UserRole.fromWire('board'), UserRole.board);
    });

    test('falha fechada para valor desconhecido, nulo ou de tipo errado', () {
      expect(UserRole.fromWire('admin'), UserRole.pending);
      expect(UserRole.fromWire(null), UserRole.pending);
      expect(UserRole.fromWire(42), UserRole.pending);
      expect(UserRole.fromWire(''), UserRole.pending);
    });
  });

  group('roteamento por persona', () {
    test('cada persona tem rota inicial distinta', () {
      final Set<String> routes = <String>{
        UserRole.operational.landingRoute,
        UserRole.strategic.landingRoute,
        UserRole.board.landingRoute,
      };
      expect(routes.length, 3);
    });

    test('pending não cai em dashboard', () {
      expect(UserRole.pending.landingRoute, '/aguardando-acesso');
      expect(UserRole.pending.isProvisioned, isFalse);
    });
  });

  test('todas as personas têm rótulo e proposta de valor preenchidos', () {
    for (final UserRole role in UserRole.values) {
      expect(role.label, isNotEmpty);
      expect(role.shortLabel, isNotEmpty);
      expect(role.valueProposition, isNotEmpty);
    }
  });
}
