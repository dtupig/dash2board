import '../../auth/domain/user_role.dart';

/// Ação sobre uma solicitação de serviço, para a mensagem explicativa de
/// [RequestPolicy.blockReason].
enum RequestAction { open, approve, view, reject }

/// A alçada de demanda, em código: **operacional abre, CISO aprova, board
/// não abre nem aprova** (`docs/08_CATALOGO_SERVICOS.md`).
///
/// Classe pura, sem Flutter, e é o único lugar do app que decide isso -
/// nenhuma tela reimplementa a regra. Se um widget precisa saber se um botão
/// aparece, ele pergunta aqui.
///
/// A regra "ninguém aprova a própria solicitação, exceto a auto-aprovação
/// marcada do `strategic`" não precisa de um método à parte: como
/// [canApprove] só é verdadeiro para `strategic`, e a solicitação aberta por
/// `strategic` já nasce aprovada (via [requiresApproval] == false, aplicado
/// na criação pela camada de dados, com um `ApprovalRecord.isSelfApproval`),
/// ela nunca chega ao estado `pendingApproval` para que alguém - inclusive
/// quem a abriu - precise "aprová-la" de novo.
abstract final class RequestPolicy {
  /// `operational` e `strategic` abrem solicitação; `board` e `pending`, não.
  static bool canOpen(UserRole role) {
    return role == UserRole.operational || role == UserRole.strategic;
  }

  /// Só `strategic` aprova ou rejeita.
  static bool canApprove(UserRole role) => role == UserRole.strategic;

  /// As três personas provisionadas veem o módulo - o que cada uma vê dentro
  /// dele (próprias, todas, ou só as com fato relevante) é filtro de dado,
  /// não desta política.
  static bool canView(UserRole role) {
    return role == UserRole.operational ||
        role == UserRole.strategic ||
        role == UserRole.board;
  }

  /// Verdadeiro quando a solicitação de [opener] precisa esperar aprovação
  /// alheia antes de seguir. `strategic` se auto-aprova ao abrir.
  static bool requiresApproval(UserRole opener) {
    return opener == UserRole.operational;
  }

  /// Mensagem para explicar um bloqueio na interface - nunca esconder um
  /// botão sem dizer por quê. `null` quando a ação é permitida.
  static String? blockReason(UserRole role, RequestAction action) {
    switch (action) {
      case RequestAction.open:
        if (canOpen(role)) {
          return null;
        }
        return role == UserRole.board
            ? 'Solicitações são abertas pelo time técnico e aprovadas pelo '
                'CISO.'
            : 'Seu acesso ainda não permite abrir solicitações.';
      case RequestAction.approve:
      case RequestAction.reject:
        if (canApprove(role)) {
          return null;
        }
        return role == UserRole.board
            ? 'O board não aprova solicitações; é informado apenas quando '
                'uma delas se torna fato relevante.'
            : 'Somente o CISO aprova ou rejeita solicitações.';
      case RequestAction.view:
        if (canView(role)) {
          return null;
        }
        return 'Seu acesso ainda não permite ver solicitações.';
    }
  }
}
