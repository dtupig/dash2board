import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('claims têm precedência sobre o documento de membro', () {
    final AppUser user = AppUser.fromFirestore(
      uid: 'uid-1',
      email: 'ciso@cliente.com',
      claims: <String, Object?>{
        'role': 'strategic',
        'tenantId': 'tenant-a',
      },
      memberDoc: <String, Object?>{
        'role': 'board',
        'tenantId': 'tenant-b',
        'displayName': 'Ana Ribeiro',
      },
    );

    expect(user.role, UserRole.strategic);
    expect(user.tenantId, 'tenant-a');
    expect(user.displayName, 'Ana Ribeiro');
  });

  test('sem claim de papel o acesso não é liberado', () {
    final AppUser user = AppUser.fromFirestore(
      uid: 'uid-2',
      email: 'novo@cliente.com',
      claims: <String, Object?>{},
    );

    expect(user.role, UserRole.pending);
    expect(user.canEnterDashboard, isFalse);
  });

  test('firstName usa displayName e cai para o e-mail quando ausente', () {
    const AppUser withName = AppUser(
      uid: 'u',
      email: 'ana.ribeiro@cliente.com',
      role: UserRole.board,
      tenantId: 't',
      displayName: 'Ana Ribeiro',
    );
    const AppUser withoutName = AppUser(
      uid: 'u',
      email: 'ana.ribeiro@cliente.com',
      role: UserRole.board,
      tenantId: 't',
    );

    expect(withName.firstName, 'Ana');
    expect(withoutName.firstName, 'Ana');
    expect(withName.initials, 'AR');
  });

  test('AppUser.empty não está autenticado', () {
    final AppUser empty = AppUser.empty();
    expect(empty.isAuthenticated, isFalse);
    expect(empty.canEnterDashboard, isFalse);
  });
}
