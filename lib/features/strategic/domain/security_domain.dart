/// Domínios de controle de segurança usados no índice de postura, no
/// mapeamento de risco por área e no filtro de compliance.
///
/// O [wireValue] é o valor persistido no Firestore
/// (`docs/01_MODELO_DADOS_FIRESTORE.md`), por isso não segue `camelCase`
/// para `thirdParty`.
enum SecurityDomain {
  /// Identidade e gestão de acesso.
  identity('identity'),

  /// Postura de endpoints (estações, notebooks, dispositivos móveis).
  endpoint('endpoint'),

  /// Configuração e exposição de ambientes em nuvem.
  cloud('cloud'),

  /// Segurança do ciclo de vida de desenvolvimento de aplicações.
  appsec('appsec'),

  /// Classificação, proteção e ciclo de vida de dados.
  data('data'),

  /// Risco introduzido por fornecedores e parceiros.
  thirdParty('thirdparty');

  const SecurityDomain(this.wireValue);

  /// Valor persistido no Firestore.
  final String wireValue;

  /// Rótulo em pt-BR exibido nos painéis.
  String get label => switch (this) {
        SecurityDomain.identity => 'Identidade e Acesso',
        SecurityDomain.endpoint => 'Endpoint',
        SecurityDomain.cloud => 'Nuvem',
        SecurityDomain.appsec => 'Segurança de Aplicações',
        SecurityDomain.data => 'Dados',
        SecurityDomain.thirdParty => 'Terceiros',
      };

  /// Converte o valor vindo do backend.
  ///
  /// Diferente de `UserRole.fromWire`, este não é uma decisão de acesso: um
  /// domínio desconhecido não pode derrubar a renderização de um card, então
  /// o fallback é apenas um valor estável ([SecurityDomain.identity]), não
  /// uma trava de segurança.
  static SecurityDomain fromWire(Object? value) {
    if (value is! String) {
      return SecurityDomain.identity;
    }
    for (final SecurityDomain domain in SecurityDomain.values) {
      if (domain.wireValue == value) {
        return domain;
      }
    }
    return SecurityDomain.identity;
  }
}
