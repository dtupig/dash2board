import 'package:firebase_auth/firebase_auth.dart';

import 'app_failure.dart';

/// Traduz erros do FirebaseAuth em [AppFailure] com mensagem segura em pt-BR.
///
/// Todos os códigos relacionados a credencial convergem para a MESMA
/// mensagem genérica, para não permitir enumeração de usuários.
abstract final class AuthErrorMapper {
  static AppFailure map(Object error) {
    if (error is AppFailure) {
      return error;
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          return const AppFailure.invalidCredentials();
        case 'user-disabled':
          return const AppFailure(
            code: 'user-disabled',
            message:
                'Esta conta está desativada. Fale com o administrador da sua '
                'organização.',
            isRecoverable: false,
          );
        case 'too-many-requests':
          return const AppFailure.tooManyAttempts();
        case 'network-request-failed':
          return const AppFailure.network();
        case 'operation-not-allowed':
          return const AppFailure(
            code: 'operation-not-allowed',
            message: 'Este método de login não está habilitado.',
            isRecoverable: false,
          );
        case 'requires-recent-login':
          return const AppFailure(
            code: 'requires-recent-login',
            message: 'Por segurança, entre novamente para concluir esta ação.',
          );
        default:
          return const AppFailure.unknown();
      }
    }
    return const AppFailure.unknown();
  }
}
