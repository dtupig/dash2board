/// As três personas atendidas pelo Elytron Dash2Board.
///
/// O papel é a origem única de verdade para:
/// * qual dashboard o usuário enxerga após o login;
/// * qual profundidade de dado é lida do Firestore;
/// * quais coleções as `firestore.rules` liberam.
///
/// O valor é gravado em DOIS lugares, sempre pelo backend:
/// 1. Custom claim do Firebase Auth (`role`) - usado nas security rules,
///    porque é assinado e não pode ser adulterado pelo cliente;
/// 2. Documento `/tenants/{tenantId}/members/{uid}.role` - usado para
///    listagem, auditoria e administração.
///
/// O aplicativo NUNCA grava o próprio papel.
enum UserRole {
  /// Persona 1 - Time técnico operacional e tático.
  /// Analistas de SOC, resposta a incidentes, vulnerability management.
  /// Precisa de granularidade máxima, tempo real e ação.
  operational('operational'),

  /// Persona 2 - Segurança estratégica e CISO.
  /// Precisa de postura consolidada, tendência, risco por domínio,
  /// compliance, orçamento e comparação com o setor.
  strategic('strategic'),

  /// Persona 3 - Board / C-Level das unidades de negócio.
  /// Precisa de impacto no negócio, exposição financeira, poucos números,
  /// linguagem sem jargão e decisão clara.
  board('board'),

  /// Usuário autenticado porém ainda sem papel provisionado.
  /// Cai numa tela de "aguardando liberação", nunca em um dashboard.
  pending('pending');

  const UserRole(this.wireValue);

  /// Valor persistido no Firestore e no custom claim.
  final String wireValue;

  /// Converte o valor vindo do backend. Desconhecido vira [UserRole.pending]
  /// - falha fechada (fail-closed), nunca abre acesso por engano.
  static UserRole fromWire(Object? value) {
    if (value is! String) {
      return UserRole.pending;
    }
    for (final UserRole role in UserRole.values) {
      if (role.wireValue == value) {
        return role;
      }
    }
    return UserRole.pending;
  }

  bool get isProvisioned => this != UserRole.pending;

  /// Nome curto exibido no chip da tela de boas-vindas.
  String get shortLabel => switch (this) {
        UserRole.operational => 'Operação',
        UserRole.strategic => 'CISO',
        UserRole.board => 'Board',
        UserRole.pending => 'Pendente',
      };

  /// Nome completo da persona.
  String get label => switch (this) {
        UserRole.operational => 'Operação & Tática de Segurança',
        UserRole.strategic => 'Segurança Estratégica / CISO',
        UserRole.board => 'Board & Executivos de Negócio',
        UserRole.pending => 'Acesso pendente',
      };

  /// Promessa de valor da persona - usada como subtítulo na tela inicial.
  String get valueProposition => switch (this) {
        UserRole.operational =>
          'Fila priorizada, incidentes em tempo real e o que precisa ser feito agora.',
        UserRole.strategic =>
          'Postura consolidada, tendência de risco, compliance e evidência para decidir.',
        UserRole.board =>
          'Exposição do negócio em números claros, sem jargão técnico.',
        UserRole.pending =>
          'Seu acesso está sendo provisionado pelo administrador da sua organização.',
      };

  /// Rota inicial após o login, resolvida pelo GoRouter.
  String get landingRoute => switch (this) {
        UserRole.operational => '/operacao',
        UserRole.strategic => '/estrategia',
        UserRole.board => '/board',
        UserRole.pending => '/aguardando-acesso',
      };
}
