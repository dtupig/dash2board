import '../domain/compliance_control.dart';
import '../domain/security_domain.dart';

/// Frase de consequência de negócio por domínio de segurança, usada na
/// seção "domínios mais fracos" do briefing executivo.
///
/// Editorial, não técnica: fala do que acontece com o negócio, não do
/// controle em si - é o que o comitê decide sobre, não o que o time de
/// segurança implementa.
extension SecurityDomainBriefingConsequence on SecurityDomain {
  String get briefingConsequence => switch (this) {
        SecurityDomain.identity =>
          'um invasor pode se passar por um funcionário e acessar sistemas '
              'críticos sem ser notado.',
        SecurityDomain.endpoint =>
          'notebooks e estações desprotegidos são a porta de entrada mais '
              'comum para um ataque que pode parar a operação por dias.',
        SecurityDomain.cloud =>
          'uma configuração exposta pode vazar dados de clientes ou '
              'derrubar sistemas usados pelo público.',
        SecurityDomain.appsec =>
          'vulnerabilidades não corrigidas em aplicações dão a um invasor '
              'caminho direto para dados de clientes ou propriedade '
              'intelectual.',
        SecurityDomain.data =>
          'dados sem classificação ou proteção adequada aumentam o custo e '
              'o tempo de resposta a um vazamento, com exposição '
              'regulatória.',
        SecurityDomain.thirdParty =>
          'um fornecedor comprometido vira porta de entrada para o '
              'ambiente da empresa sem que nenhum controle interno perceba.',
      };
}

/// Nome do framework com a sigla explicada por extenso, na mesma linha -
/// regra do briefing executivo ("nenhuma sigla sem explicação").
extension ComplianceFrameworkBriefingName on ComplianceFramework {
  String get briefingFullName => switch (this) {
        ComplianceFramework.iso27001 =>
          'ISO 27001 (norma internacional de segurança da informação)',
        ComplianceFramework.nistCsf =>
          'NIST CSF (guia de boas práticas de cibersegurança do órgão '
              'americano NIST)',
        ComplianceFramework.lgpd => 'LGPD (Lei Geral de Proteção de Dados)',
        ComplianceFramework.pciDss =>
          'PCI DSS (padrão de segurança de dados do setor de cartão de '
              'pagamento)',
      };
}
