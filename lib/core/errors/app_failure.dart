/// Erro de domínio já traduzido para uma mensagem exibível ao usuário.
///
/// Regra de segurança: a mensagem NUNCA revela se um e-mail existe na base,
/// se a senha está errada ou detalhes internos do backend. Enumeração de
/// usuários é um vetor real de ataque em produtos B2B.
class AppFailure implements Exception {
  const AppFailure({
    required this.code,
    required this.message,
    this.isRecoverable = true,
  });

  const AppFailure.unknown()
      : code = 'unknown',
        message = 'Não foi possível concluir a operação. Tente novamente.',
        isRecoverable = true;

  const AppFailure.network()
      : code = 'network',
        message =
            'Sem conexão com os servidores da Elytron. Verifique sua rede.',
        isRecoverable = true;

  const AppFailure.invalidCredentials()
      : code = 'invalid-credentials',
        message = 'E-mail ou senha inválidos.',
        isRecoverable = true;

  const AppFailure.tooManyAttempts()
      : code = 'too-many-attempts',
        message =
            'Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.',
        isRecoverable = true;

  const AppFailure.accessNotProvisioned()
      : code = 'not-provisioned',
        message =
            'Sua conta ainda não tem perfil liberado. Fale com o administrador '
                'da sua organização.',
        isRecoverable = false;

  final String code;
  final String message;
  final bool isRecoverable;

  @override
  String toString() => 'AppFailure($code): $message';
}
