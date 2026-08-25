/// Nível de sigilo de um relatório inteiro.
///
/// Determina, junto com [SectionSensitivity] e a persona, o que
/// `ReportAccessPolicy` libera - nunca uma tela decide isso sozinha.
enum ReportClassification {
  /// Pode circular livremente dentro do tenant - ex.: sumário de catálogo.
  publicInternal('public_internal'),

  /// Uso interno do cliente; não deveria sair da organização.
  restricted('restricted'),

  /// Contém prova de conceito, achado técnico detalhado ou dado de negócio
  /// sensível. A maioria dos relatórios de serviço vive aqui.
  confidential('confidential'),

  /// Perícia forense, investigação, cadeia de custódia ou dado pessoal em
  /// volume. Leitura exige registro (`readReceipt`) antes de renderizar.
  secret('secret');

  const ReportClassification(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        ReportClassification.publicInternal => 'Uso interno',
        ReportClassification.restricted => 'Restrito',
        ReportClassification.confidential => 'Confidencial',
        ReportClassification.secret => 'Sigiloso',
      };

  /// Desconhecido cai em [secret] - fail-closed: nunca assume que um
  /// relatório sem classificação reconhecida é seguro para circular.
  static ReportClassification fromWire(Object? value) {
    for (final ReportClassification c in ReportClassification.values) {
      if (c.wireValue == value) {
        return c;
      }
    }
    return ReportClassification.secret;
  }
}

/// Sensibilidade de uma seção dentro de um relatório - granularidade menor
/// que a classificação do documento inteiro.
///
/// Nota de arquitetura (validação D-27 contra relatórios reais): evidência
/// em **imagem** (captura de tela, screenshot de terminal) é uma unidade
/// atômica de sensibilidade. Esta enum não sabe redigir parte de uma
/// imagem - se uma captura mistura conteúdo de sensibilidades diferentes,
/// a redação acontece na própria imagem, antes de anexar (orientação
/// editorial do prompt 13), nunca em tempo de renderização aqui.
enum SectionSensitivity {
  /// Texto de negócio, sem jargão técnico nem prova de exploração.
  narrative('narrative'),

  /// Achado técnico, IOC, métrica - não é prova de exploração nem dado
  /// pessoal.
  technical('technical'),

  /// Passo de reprodução, payload, captura de acesso bem-sucedido.
  exploitProof('exploit_proof'),

  /// Dado pessoal identificável de um titular (CPF, e-mail, nome, cartão).
  personalData('personal_data'),

  /// Metadado de cadeia de custódia forense (identificador de dispositivo,
  /// hash de aquisição, custodiante).
  chainOfCustody('chain_of_custody');

  const SectionSensitivity(this.wireValue);

  final String wireValue;

  /// Desconhecido cai na sensibilidade mais restritiva - fail-closed.
  static SectionSensitivity fromWire(Object? value) {
    for (final SectionSensitivity s in SectionSensitivity.values) {
      if (s.wireValue == value) {
        return s;
      }
    }
    return SectionSensitivity.exploitProof;
  }
}
