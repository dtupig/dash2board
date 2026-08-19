/// Caminhos canônicos das coleções do Cloud Firestore.
///
/// Centralizar aqui evita strings mágicas espalhadas e mantém o código
/// alinhado com `firestore.rules` e `firestore.indexes.json`.
///
/// Modelo multi-tenant: quase tudo vive sob `/tenants/{tenantId}/...`,
/// porque o Dash2Board atende várias organizações (clientes Elytron) e o
/// isolamento por tenant é o principal controle de segurança do produto.
abstract final class FirestorePaths {
  // Raiz global
  static const String users = 'users';
  static const String tenants = 'tenants';
  static const String invites = 'invites';

  static String user(String uid) => '$users/$uid';
  static String tenant(String tenantId) => '$tenants/$tenantId';

  // Subcoleções por tenant
  static String members(String tenantId) => '${tenant(tenantId)}/members';
  static String member(String tenantId, String uid) =>
      '${members(tenantId)}/$uid';

  /// Métricas agregadas prontas para leitura (uma leitura por card).
  static String metrics(String tenantId) => '${tenant(tenantId)}/metrics';
  static String metric(String tenantId, String metricId) =>
      '${metrics(tenantId)}/$metricId';

  /// Snapshots diários de postura para gráficos de tendência.
  static String postureSnapshots(String tenantId) =>
      '${tenant(tenantId)}/posture_snapshots';

  /// Incidentes / casos de resposta (persona operacional).
  static String incidents(String tenantId) => '${tenant(tenantId)}/incidents';

  /// Vulnerabilidades priorizadas (persona operacional e estratégica).
  static String vulnerabilities(String tenantId) =>
      '${tenant(tenantId)}/vulnerabilities';

  /// Riscos de negócio traduzidos para linguagem executiva (persona board).
  static String risks(String tenantId) => '${tenant(tenantId)}/risks';

  /// Itens de compliance por framework (ISO 27001, NIST CSF, LGPD, PCI).
  static String compliance(String tenantId) => '${tenant(tenantId)}/compliance';

  /// Relatórios publicados (PDF/painel) por período.
  static String reports(String tenantId) => '${tenant(tenantId)}/reports';

  /// Insights e tendências curados pela Elytron.
  static String insights(String tenantId) => '${tenant(tenantId)}/insights';

  /// Pesquisas / surveys enviadas a CISOs e executivos.
  static String surveys(String tenantId) => '${tenant(tenantId)}/surveys';
  static String survey(String tenantId, String surveyId) =>
      '${surveys(tenantId)}/$surveyId';

  /// Respostas de uma pesquisa, isoladas por usuário
  /// (`/tenants/{tenantId}/surveys/{surveyId}/responses/{uid}`).
  static String surveyResponses(String tenantId, String surveyId) =>
      '${survey(tenantId, surveyId)}/responses';
  static String surveyResponse(
    String tenantId,
    String surveyId,
    String uid,
  ) =>
      '${surveyResponses(tenantId, surveyId)}/$uid';

  /// Trilha de auditoria (append-only, somente via Cloud Functions).
  static String auditLogs(String tenantId) => '${tenant(tenantId)}/audit_logs';

  /// Preferências de UI por usuário dentro do tenant.
  static String preferences(String tenantId, String uid) =>
      '${tenant(tenantId)}/preferences/$uid';
}
