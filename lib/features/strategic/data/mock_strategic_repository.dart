import '../domain/compliance_control.dart';
import '../domain/insight_item.dart';
import '../domain/posture_index.dart';
import '../domain/posture_snapshot.dart';
import '../domain/risk_item.dart';
import '../domain/survey.dart';
import '../domain/tenant_profile.dart';
import 'mock/mock_strategic_compliance_iso_nist.dart';
import 'mock/mock_strategic_compliance_lgpd_pci.dart';
import 'mock/mock_strategic_insights.dart';
import 'mock/mock_strategic_posture.dart';
import 'mock/mock_strategic_risks.dart';
import 'mock/mock_strategic_survey.dart';
import 'mock/mock_strategic_tenant_profile.dart';
import 'strategic_repository.dart';

/// Dados de demonstração da persona estratégica, 100% em memória.
///
/// Conta a história de uma empresa brasileira de médio porte: postura em
/// melhora constante, com um recuo pontual, terceiros e appsec como as áreas
/// que ainda pedem atenção, e uma carteira de risco plausível para comitê.
///
/// Nada aqui usa `Random()` ou `DateTime.now()`: todo dado nasce de uma data
/// de referência fixa ([_anchor]), para que a demonstração seja
/// **reproduzível**. Os construtores de cada bloco de dado vivem em
/// `data/mock/mock_strategic_*.dart`, um arquivo por domínio, para manter
/// este arquivo abaixo do limite de 250 linhas.
class MockStrategicRepository implements StrategicRepository {
  static const Duration _streamDelay = Duration(milliseconds: 400);

  /// Data de referência da demonstração ("hoje" na narrativa do painel).
  static final DateTime _anchor = DateTime.utc(2026, 8, 1);

  @override
  Stream<PostureIndex> watchPostureIndex(String tenantId) {
    return _afterDelay(() => buildPostureIndex(_anchor));
  }

  @override
  Stream<List<PostureSnapshot>> watchPostureHistory(
    String tenantId, {
    int months = 12,
  }) {
    return _afterDelay(() => buildPostureHistory(_anchor, months: months));
  }

  @override
  Stream<List<ComplianceControl>> watchCompliance(
    String tenantId, {
    ComplianceFramework? framework,
  }) {
    return _afterDelay(() {
      final List<ComplianceControl> all = <ComplianceControl>[
        ...buildComplianceControlsIsoNist(_anchor),
        ...buildComplianceControlsLgpdPci(_anchor),
      ];
      if (framework == null) {
        return all;
      }
      return all
          .where((ComplianceControl control) => control.framework == framework)
          .toList(growable: false);
    });
  }

  @override
  Stream<List<RiskItem>> watchTopRisks(String tenantId, {int limit = 5}) {
    return _afterDelay(() {
      final List<RiskItem> risks = _sortedByAleDesc(_riskItems);
      return risks.take(limit).toList(growable: false);
    });
  }

  @override
  Stream<List<RiskItem>> watchAllRisks(String tenantId) {
    return _afterDelay(() => _sortedByAleDesc(_riskItems));
  }

  List<RiskItem> _sortedByAleDesc(List<RiskItem> risks) {
    return List<RiskItem>.of(risks)
      ..sort((RiskItem a, RiskItem b) =>
          b.annualLossExpectancy.compareTo(a.annualLossExpectancy));
  }

  @override
  Stream<TenantProfile> watchTenantProfile(String tenantId) {
    return _afterDelay(buildTenantProfile);
  }

  @override
  Future<void> recordRiskDecision({
    required String tenantId,
    required String riskId,
    required RiskAcceptance decision,
    required String actorUid,
    required String boardNote,
  }) async {
    await Future<void>.delayed(_streamDelay);
    final int index = _riskItems.indexWhere((RiskItem r) => r.id == riskId);
    if (index == -1) {
      return;
    }
    // Só os campos que `firestore.rules` libera para o papel `board` -
    // nenhum outro campo do risco muda aqui, nem no mock.
    _riskItems[index] = _riskItems[index].copyWith(acceptance: decision);
  }

  @override
  Stream<List<InsightItem>> watchInsights(String tenantId, {int limit = 10}) {
    return _afterDelay(() {
      final List<InsightItem> insights = buildInsights(_anchor);
      return insights.take(limit).toList(growable: false);
    });
  }

  /// Estado dos riscos NESTA execução do app: começa com os riscos iniciais
  /// e muda quando o board registra uma decisão. Em memória, como todo o
  /// resto do mock.
  late final List<RiskItem> _riskItems = buildInitialRisks(_anchor);

  /// Respostas gravadas nesta execução do app, por uid. Deliberadamente só
  /// em memória: reinicia zerado a cada execução, como um mock deve ser.
  final Map<String, Map<String, String>> _surveyResponsesByUid =
      <String, Map<String, String>>{};

  Survey _activeSurvey(String uid) {
    return Survey(
      id: activeSurveyId,
      title: 'Prioridades de segurança para 2027',
      description:
          'Leva menos de um minuto. Ao final, veja como sua resposta se '
          'compara à de outros CISOs do seu setor.',
      questions: buildSurveyQuestions(),
      respondentCount: baseRespondentCount + _surveyResponsesByUid.length,
      yourAnswers: _surveyResponsesByUid[uid],
    );
  }

  @override
  Stream<Survey?> watchActiveSurvey(String tenantId, String uid) {
    return _afterDelay(() => _activeSurvey(uid));
  }

  @override
  Future<void> submitSurveyResponse({
    required String tenantId,
    required String surveyId,
    required String uid,
    required Map<String, String> answers,
  }) async {
    await Future<void>.delayed(_streamDelay);
    _surveyResponsesByUid[uid] = Map<String, String>.of(answers);
  }

  Stream<T> _afterDelay<T>(T Function() compute) async* {
    await Future<void>.delayed(_streamDelay);
    yield compute();
  }
}
