import '../domain/app_user.dart';

/// Contrato de autenticação usado por toda a camada de apresentação.
///
/// Existem duas implementações:
/// * [FirebaseAuthRepository] - produção, em `firebase_auth_repository.dart`;
/// * [MockAuthRepository] - demonstração offline, em `mock_auth_repository.dart`.
///
/// A escolha acontece uma única vez, em `authRepositoryProvider`. Nenhuma tela
/// sabe qual está ativa.
abstract interface class AuthRepository {
  /// Emite o usuário resolvido (com papel e tenant) a cada mudança de sessão.
  /// `null` significa "não autenticado".
  Stream<AppUser?> watchCurrentUser();

  /// Usuário atual resolvido sob demanda.
  Future<AppUser?> currentUser();

  /// Reavalia os custom claims (após o admin provisionar o papel).
  Future<AppUser?> refreshClaims();

  /// Login com e-mail corporativo e senha.
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Envia e-mail de redefinição de senha, com resposta uniforme.
  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
