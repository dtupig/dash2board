import '../domain/compliance_control.dart';
import '../domain/insight_item.dart';
import '../domain/posture_index.dart';
import '../domain/posture_snapshot.dart';
import '../domain/risk_item.dart';
import '../domain/survey.dart';
import '../domain/tenant_profile.dart';

/// Contrato de leitura de dados da persona estratégica (CISO).
///
/// Existem duas implementações:
/// * [MockStrategicRepository] - demonstração offline, com dados fixos e
///   reproduzíveis, em `mock_strategic_repository.dart`;
/// * [FirestoreStrategicRepository] - produção, sobre Cloud Firestore, em
///   `firestore_strategic_repository.dart`.
///
/// A escolha acontece uma única vez, em `strategic_providers.dart`. Nenhuma
/// tela sabe qual está ativa.
abstract interface class StrategicRepository {
  /// Índice de postura consolidado de hoje.
  Stream<PostureIndex> watchPostureIndex(String tenantId);

  /// Série histórica do índice geral, um ponto por mês.
  Stream<List<PostureSnapshot>> watchPostureHistory(
    String tenantId, {
    int months = 12,
  });

  /// Controles de compliance, opcionalmente filtrados por framework.
  Stream<List<ComplianceControl>> watchCompliance(
    String tenantId, {
    ComplianceFramework? framework,
  });

  /// Riscos de negócio de maior exposição, ordenados por relevância.
  Stream<List<RiskItem>> watchTopRisks(String tenantId, {int limit = 5});

  /// Todos os riscos abertos do tenant, sem limite - usado pelo painel do
  /// board para somar exposição total e agrupar por unidade de negócio, onde
  /// um "top N" arbitrário sub-representaria a exposição real.
  Stream<List<RiskItem>> watchAllRisks(String tenantId);

  /// Perfil financeiro e organizacional do tenant (receita anual e o
  /// executivo dono de cada unidade de negócio) - usado pelo painel do
  /// board para expressar exposição como percentual da receita e nomear um
  /// responsável por risco.
  Stream<TenantProfile> watchTenantProfile(String tenantId);

  /// Registra a decisão do board sobre um risco: aceitar ou pedir um plano
  /// de mitigação ao CISO.
  ///
  /// Grava só os campos que `firestore.rules` libera para o papel `board`
  /// (`acceptance`, `acceptedByUid`, `acceptedAt`, `boardNote`) - nunca
  /// nenhum outro campo do risco. Em produção, a escrita dispara uma Cloud
  /// Function que registra o evento na trilha de auditoria.
  Future<void> recordRiskDecision({
    required String tenantId,
    required String riskId,
    required RiskAcceptance decision,
    required String actorUid,
    required String boardNote,
  });

  /// Insights, tendências e pesquisas curadas pela Elytron.
  Stream<List<InsightItem>> watchInsights(String tenantId, {int limit = 10});

  /// Pesquisa ativa do tenant, já com a resposta de [uid] embutida em
  /// `Survey.yourAnswers` quando ele já respondeu. `null` quando não há
  /// pesquisa ativa no momento.
  Stream<Survey?> watchActiveSurvey(String tenantId, String uid);

  /// Grava a resposta de [uid] à pesquisa [surveyId].
  ///
  /// No mock, a resposta fica só em memória (perde-se ao reiniciar o app);
  /// em produção grava em `surveys/{surveyId}/responses/{uid}`.
  Future<void> submitSurveyResponse({
    required String tenantId,
    required String surveyId,
    required String uid,
    required Map<String, String> answers,
  });
}
