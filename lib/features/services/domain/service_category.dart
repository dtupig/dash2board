/// As 8 categorias do catálogo de serviços Elytron.
///
/// Fonte única de verdade: `docs/08_CATALOGO_SERVICOS.md`. `categoryKey` é
/// `snake_case`, estável, e nunca muda depois de publicado - ele é gravado em
/// relatórios já emitidos.
enum ServiceCategory {
  pentest('pentest'),
  appsec('appsec'),
  attackSurface('attack_surface'),
  response('response'),
  governance('governance'),
  vulnerability('vulnerability'),
  thirdParty('third_party'),
  defense('defense');

  const ServiceCategory(this.categoryKey);

  /// Valor persistido no Firestore e usado como chave de agrupamento.
  final String categoryKey;

  /// Rótulo em pt-BR, livre para reescrever a qualquer momento.
  String get label => switch (this) {
        ServiceCategory.pentest => 'Testes de Penetração',
        ServiceCategory.appsec => 'Segurança de Aplicação',
        ServiceCategory.attackSurface => 'Superfície de Ataque',
        ServiceCategory.response => 'Resposta e Crise',
        ServiceCategory.governance => 'Risco e Governança',
        ServiceCategory.vulnerability => 'Gestão de Vulnerabilidades',
        ServiceCategory.thirdParty => 'Gestão de Terceiros',
        ServiceCategory.defense => 'Defesa e Inteligência',
      };

  /// Descrição curta em linguagem de negócio, usada no cabeçalho do grupo no
  /// catálogo.
  String get description => switch (this) {
        ServiceCategory.pentest =>
          'Simula um ataque real para achar a falha antes de quem quer explorá-la.',
        ServiceCategory.appsec =>
          'Segurança embutida no ciclo de desenvolvimento de software.',
        ServiceCategory.attackSurface =>
          'O que a sua empresa expõe à internet, visto de fora para dentro.',
        ServiceCategory.response =>
          'Preparação, contenção e investigação quando o incidente já aconteceu.',
        ServiceCategory.governance =>
          'Estrutura, política e conformidade regulatória do programa de segurança.',
        ServiceCategory.vulnerability =>
          'Priorização e acompanhamento das falhas conhecidas do seu ambiente.',
        ServiceCategory.thirdParty =>
          'O risco que entra pela porta dos fornecedores e parceiros.',
        ServiceCategory.defense =>
          'Detecção, resposta automatizada e inteligência contra ameaças ativas.',
      };

  /// Converte o valor vindo do backend. Chave desconhecida cai na primeira
  /// categoria - não é uma decisão de segurança (como em `UserRole`), apenas
  /// um valor de agrupamento visual que nunca deve travar a tela.
  static ServiceCategory fromWire(Object? value) {
    if (value is! String) {
      return ServiceCategory.pentest;
    }
    for (final ServiceCategory category in ServiceCategory.values) {
      if (category.categoryKey == value) {
        return category;
      }
    }
    return ServiceCategory.pentest;
  }
}
