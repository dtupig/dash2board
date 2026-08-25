import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/services/domain/request_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canOpen', () {
    test('operational e strategic abrem', () {
      expect(RequestPolicy.canOpen(UserRole.operational), isTrue);
      expect(RequestPolicy.canOpen(UserRole.strategic), isTrue);
    });

    test('board NÃO abre', () {
      expect(RequestPolicy.canOpen(UserRole.board), isFalse);
    });

    test('pending NÃO abre', () {
      expect(RequestPolicy.canOpen(UserRole.pending), isFalse);
    });
  });

  group('canApprove', () {
    test('apenas strategic aprova', () {
      expect(RequestPolicy.canApprove(UserRole.strategic), isTrue);
    });

    test('operational NÃO aprova', () {
      expect(RequestPolicy.canApprove(UserRole.operational), isFalse);
    });

    test('board NÃO aprova', () {
      expect(RequestPolicy.canApprove(UserRole.board), isFalse);
    });

    test('pending NÃO aprova', () {
      expect(RequestPolicy.canApprove(UserRole.pending), isFalse);
    });
  });

  group('canView', () {
    test('as três personas provisionadas veem o módulo', () {
      expect(RequestPolicy.canView(UserRole.operational), isTrue);
      expect(RequestPolicy.canView(UserRole.strategic), isTrue);
      expect(RequestPolicy.canView(UserRole.board), isTrue);
    });

    test('pending NÃO vê', () {
      expect(RequestPolicy.canView(UserRole.pending), isFalse);
    });
  });

  group('requiresApproval', () {
    test('operational precisa de aprovação alheia', () {
      expect(RequestPolicy.requiresApproval(UserRole.operational), isTrue);
    });

    test('strategic se auto-aprova - nunca fica pendente de terceiro', () {
      expect(RequestPolicy.requiresApproval(UserRole.strategic), isFalse);
    });
  });

  group('blockReason', () {
    test('ação permitida devolve null', () {
      expect(
        RequestPolicy.blockReason(UserRole.operational, RequestAction.open),
        isNull,
      );
      expect(
        RequestPolicy.blockReason(UserRole.strategic, RequestAction.approve),
        isNull,
      );
      expect(
        RequestPolicy.blockReason(UserRole.board, RequestAction.view),
        isNull,
      );
    });

    test('board bloqueado em abrir explica a alçada, não esconde sem motivo',
        () {
      final String? reason =
          RequestPolicy.blockReason(UserRole.board, RequestAction.open);
      expect(reason, isNotNull);
      expect(reason, contains('CISO'));
    });

    test('operational bloqueado em aprovar/rejeitar tem explicação', () {
      expect(
        RequestPolicy.blockReason(UserRole.operational, RequestAction.approve),
        isNotNull,
      );
      expect(
        RequestPolicy.blockReason(UserRole.operational, RequestAction.reject),
        isNotNull,
      );
    });

    test('board bloqueado em aprovar explica o mecanismo de fato relevante',
        () {
      final String? reason =
          RequestPolicy.blockReason(UserRole.board, RequestAction.approve);
      expect(reason, isNotNull);
      expect(reason, contains('fato relevante'));
    });

    test('pending bloqueado em ver tem explicação', () {
      expect(
        RequestPolicy.blockReason(UserRole.pending, RequestAction.view),
        isNotNull,
      );
    });
  });
}
