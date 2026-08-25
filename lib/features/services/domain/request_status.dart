/// Estado de uma solicitação de serviço (RFS) ao longo do seu ciclo de vida.
///
/// ```
/// draft ──► pendingApproval ──► approved ──► sentToElytron ──► proposalReceived
///   │             │                 │                                  │
///   │             ▼                 ▼                                  ▼
///   └──────► cancelled          rejected                          contracted
///                                                                     │
///                                                                     ▼
///                                                                 delivered
/// ```
///
/// As transições válidas vivem em [RequestStatus.validNextStates] - uma
/// tentativa de transição fora deste mapa é um bug, não uma condição de
/// negócio, e por isso [canTransitionTo] lança [StateError] em vez de
/// devolver `false`.
enum RequestStatus {
  draft('draft'),
  pendingApproval('pending_approval'),
  approved('approved'),
  rejected('rejected'),
  sentToElytron('sent_to_elytron'),
  proposalReceived('proposal_received'),
  contracted('contracted'),
  delivered('delivered'),
  cancelled('cancelled');

  const RequestStatus(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        RequestStatus.draft => 'Rascunho',
        RequestStatus.pendingApproval => 'Aguardando aprovação',
        RequestStatus.approved => 'Aprovada',
        RequestStatus.rejected => 'Rejeitada',
        RequestStatus.sentToElytron => 'Enviada à Elytron',
        RequestStatus.proposalReceived => 'Proposta recebida',
        RequestStatus.contracted => 'Contratada',
        RequestStatus.delivered => 'Entregue',
        RequestStatus.cancelled => 'Cancelada',
      };

  /// Estado sem nenhuma transição de saída - fim de linha do fluxo.
  bool get isTerminal => validNextStates.isEmpty;

  /// Mapa fechado de transições válidas. Único lugar do código que decide o
  /// que pode virar o quê - nenhuma tela reimplementa esta regra.
  static const Map<RequestStatus, Set<RequestStatus>> _transitions =
      <RequestStatus, Set<RequestStatus>>{
    RequestStatus.draft: <RequestStatus>{
      RequestStatus.pendingApproval,
      RequestStatus.cancelled,
    },
    RequestStatus.pendingApproval: <RequestStatus>{
      RequestStatus.approved,
      RequestStatus.rejected,
      RequestStatus.cancelled,
    },
    RequestStatus.approved: <RequestStatus>{RequestStatus.sentToElytron},
    RequestStatus.rejected: <RequestStatus>{},
    RequestStatus.sentToElytron: <RequestStatus>{
      RequestStatus.proposalReceived,
    },
    RequestStatus.proposalReceived: <RequestStatus>{RequestStatus.contracted},
    RequestStatus.contracted: <RequestStatus>{RequestStatus.delivered},
    RequestStatus.delivered: <RequestStatus>{},
    RequestStatus.cancelled: <RequestStatus>{},
  };

  Set<RequestStatus> get validNextStates =>
      _transitions[this] ?? const <RequestStatus>{};

  /// Lança [StateError] quando [next] não é uma transição válida a partir
  /// deste estado - transição inválida é erro de programação, nunca um
  /// resultado silencioso.
  void canTransitionTo(RequestStatus next) {
    if (!validNextStates.contains(next)) {
      throw StateError(
        'Transição inválida: $wireValue -> ${next.wireValue}.',
      );
    }
  }

  /// Valor desconhecido cai em [RequestStatus.draft] - fail-closed: nunca
  /// assume que uma solicitação já foi aprovada ou enviada quando a origem
  /// de dado não confirmou.
  static RequestStatus fromWire(Object? value) {
    if (value is! String) {
      return RequestStatus.draft;
    }
    for (final RequestStatus status in RequestStatus.values) {
      if (status.wireValue == value) {
        return status;
      }
    }
    return RequestStatus.draft;
  }
}
