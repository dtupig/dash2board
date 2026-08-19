import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/firestore_paths.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/auth_error_mapper.dart';
import '../domain/app_user.dart';
import 'auth_repository.dart';

/// Implementação de produção sobre FirebaseAuth + Cloud Firestore.
///
/// Princípios:
/// * O papel (`role`) e o `tenantId` vêm dos **custom claims** do ID token,
///   que são assinados pelo backend. O documento do membro só complementa
///   dados de exibição.
/// * Nenhuma escrita de papel parte do cliente.
/// * Erros do Firebase nunca vazam para a UI: sempre viram [AppFailure].
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _auth.idTokenChanges().asyncMap(_resolve);
  }

  @override
  Future<AppUser?> currentUser() => _resolve(_auth.currentUser);

  @override
  Future<AppUser?> refreshClaims() =>
      _resolve(_auth.currentUser, forceRefresh: true);

  Future<AppUser?> _resolve(User? user, {bool forceRefresh = false}) async {
    if (user == null) {
      return null;
    }

    final IdTokenResult token = await user.getIdTokenResult(forceRefresh);
    final Map<String, Object?> claims = <String, Object?>{
      ...?token.claims,
    };

    final String tenantId = (claims['tenantId'] as String?) ?? '';
    Map<String, Object?> memberDoc = const <String, Object?>{};

    if (tenantId.isNotEmpty) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
            .doc(FirestorePaths.member(tenantId, user.uid))
            .get()
            .timeout(AppConfig.networkTimeout);
        memberDoc = snapshot.data() ?? const <String, Object?>{};
      } on Object {
        // Perfil indisponível não derruba a sessão: o app segue com os
        // claims, que já bastam para roteamento e security rules.
        memberDoc = const <String, Object?>{};
      }
    }

    return AppUser.fromFirestore(
      uid: user.uid,
      email: user.email ?? '',
      claims: claims,
      memberDoc: memberDoc,
      emailVerified: user.emailVerified,
      mfaEnrolled: claims['mfa'] == true,
      lastSignInAt: user.metadata.lastSignInTime,
    );
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(AppConfig.networkTimeout);

      // Força o refresh para pegar claims recém-provisionados pelo backend.
      final AppUser? resolved =
          await _resolve(credential.user, forceRefresh: true);

      if (resolved == null) {
        throw const AppFailure.unknown();
      }
      return resolved;
    } on Object catch (error) {
      throw AuthErrorMapper.map(error);
    }
  }

  /// Sempre retorna com sucesso para o chamador mesmo quando o e-mail não
  /// existe - resposta uniforme evita enumeração de usuários.
  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(AppConfig.networkTimeout);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'network-request-failed') {
        throw const AppFailure.network();
      }
      // Demais códigos são silenciados de propósito.
    } on Object {
      // Idem.
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object catch (error) {
      throw AuthErrorMapper.map(error);
    }
  }
}
