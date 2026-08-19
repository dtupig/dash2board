import 'dart:async';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/app_user.dart';
import '../domain/user_role.dart';
import 'auth_repository.dart';

/// Autenticação de demonstração, 100% em memória.
///
/// Ativada por `--dart-define=MOCK=true`. Permite rodar e demonstrar o
/// aplicativo inteiro sem projeto Firebase, sem rede e sem seed.
///
/// Contas (senha: qualquer texto com 12+ caracteres):
///   operacao@demo.elytron  -> persona operacional
///   ciso@demo.elytron      -> persona estratégica (CISO)
///   board@demo.elytron     -> persona board
class MockAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  AppUser? _current;

  /// Fecha o controlador. Registrado via `ref.onDispose` no provider.
  Future<void> dispose() => _controller.close();

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AppUser?> currentUser() async => _current;

  @override
  Future<AppUser?> refreshClaims() async => _current;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Latência simulada para que os estados de carregamento sejam exercitados.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final String normalized = email.trim().toLowerCase();
    final String? wireRole = AppConfig.demoAccounts[normalized];

    if (wireRole == null || password.length < AppConfig.minDemoPasswordLength) {
      throw const AppFailure.invalidCredentials();
    }

    final UserRole role = UserRole.fromWire(wireRole);
    final AppUser user = AppUser(
      uid: 'demo-${role.wireValue}',
      email: normalized,
      role: role,
      tenantId: AppConfig.demoTenantId,
      displayName: _displayNameFor(role),
      jobTitle: _jobTitleFor(role),
      businessUnit: 'Corporativo',
      emailVerified: true,
      mfaEnrolled: true,
      lastSignInAt: DateTime.now(),
    );

    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _current = null;
    _controller.add(null);
  }

  static String _displayNameFor(UserRole role) => switch (role) {
        UserRole.operational => 'Rafael Moura',
        UserRole.strategic => 'Ana Ribeiro',
        UserRole.board => 'Cláudia Menezes',
        UserRole.pending => 'Convidado',
      };

  static String _jobTitleFor(UserRole role) => switch (role) {
        UserRole.operational => 'Analista de SOC',
        UserRole.strategic => 'CISO',
        UserRole.board => 'Diretora de Unidade de Negócio',
        UserRole.pending => 'Acesso pendente',
      };
}
