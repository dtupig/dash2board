import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../domain/compliance_control.dart';
import '../domain/insight_item.dart';
import '../domain/posture_index.dart';
import '../domain/posture_snapshot.dart';
import '../domain/risk_item.dart';
import '../domain/survey.dart';
import '../domain/tenant_profile.dart';
import 'firestore_strategic_repository.dart';
import 'mock_strategic_repository.dart';
import 'strategic_repository.dart';

/// Repositório de dados da persona estratégica (substituível em testes com
/// `overrideWith`). Este é o único ponto do app que sabe se os dados vêm do
/// mock ou do Firestore.
final Provider<StrategicRepository> strategicRepositoryProvider =
    Provider<StrategicRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockStrategicRepository();
  }
  return FirestoreStrategicRepository();
});

/// `tenantId` do usuário autenticado, ou `null` enquanto não há sessão
/// resolvida ou o usuário ainda não tem tenant provisionado.
String? _watchTenantId(Ref ref) {
  final String? tenantId = ref.watch(appUserProvider).value?.tenantId;
  return (tenantId == null || tenantId.isEmpty) ? null : tenantId;
}

/// `uid` do usuário autenticado, ou `null` nas mesmas condições acima -
/// necessário para saber se ELE já respondeu a pesquisa ativa.
String? _watchUid(Ref ref) {
  final String? uid = ref.watch(appUserProvider).value?.uid;
  return (uid == null || uid.isEmpty) ? null : uid;
}

/// Índice de postura consolidado de hoje.
final StreamProvider<PostureIndex> postureIndexProvider =
    StreamProvider<PostureIndex>((ref) {
  final String? tenantId = _watchTenantId(ref);
  if (tenantId == null) {
    return Stream<PostureIndex>.value(PostureIndex.empty());
  }
  return ref.watch(strategicRepositoryProvider).watchPostureIndex(tenantId);
});

/// Série histórica do índice geral (12 meses por padrão).
final StreamProvider<List<PostureSnapshot>> postureHistoryProvider =
    StreamProvider<List<PostureSnapshot>>((ref) {
  final String? tenantId = _watchTenantId(ref);
  if (tenantId == null) {
    return Stream<List<PostureSnapshot>>.value(const <PostureSnapshot>[]);
  }
  return ref.watch(strategicRepositoryProvider).watchPostureHistory(tenantId);
});

/// Controles de compliance de todos os frameworks.
final StreamProvider<List<ComplianceControl>> complianceProvider =
    StreamProvider<List<ComplianceControl>>((ref) {
  final String? tenantId = _watchTenantId(ref);
  if (tenantId == null) {
    return Stream<List<ComplianceControl>>.value(const <ComplianceControl>[]);
  }
  return ref.watch(strategicRepositoryProvider).watchCompliance(tenantId);
});

/// Riscos de negócio de maior exposição.
final StreamProvider<List<RiskItem>> topRisksProvider =
    StreamProvider<List<RiskItem>>((ref) {
  final String? tenantId = _watchTenantId(ref);
  if (tenantId == null) {
    return Stream<List<RiskItem>>.value(const <RiskItem>[]);
  }
  return ref.watch(strategicRepositoryProvider).watchTopRisks(tenantId);
});

/// Todos os riscos abertos do tenant, sem limite - usado pelo painel do
/// board (soma de exposição e agrupamento por unidade de negócio).
final StreamProvider<List<RiskItem>> allRisksProvider =
    StreamProvider<List<RiskItem>>((ref) {
  final String? tenantId = _watchTenantId(ref);
  if (tenantId == null) {
    return Stream<List<RiskItem>>.value(const <RiskItem>[]);
  }
  return ref.watch(strategicRepositoryProvider).watchAllRisks(tenantId);
});

/// Perfil financeiro e organizacional do tenant - usado pelo painel do
/// board.
final StreamProvider<TenantProfile> tenantProfileProvider =
    StreamProvider<TenantProfile>((ref) {
  final String? tenantId = _watchTenantId(ref);
  if (tenantId == null) {
    return Stream<TenantProfile>.value(TenantProfile.empty());
  }
  return ref.watch(strategicRepositoryProvider).watchTenantProfile(tenantId);
});

/// Insights, tendências e pesquisas curadas pela Elytron.
final StreamProvider<List<InsightItem>> insightsProvider =
    StreamProvider<List<InsightItem>>((ref) {
  final String? tenantId = _watchTenantId(ref);
  if (tenantId == null) {
    return Stream<List<InsightItem>>.value(const <InsightItem>[]);
  }
  return ref.watch(strategicRepositoryProvider).watchInsights(tenantId);
});

/// Pesquisa ativa do tenant, já com a resposta do usuário atual embutida
/// quando ele já respondeu. `null` enquanto não há sessão resolvida, sem
/// tenant, ou quando não existe pesquisa ativa no momento.
final StreamProvider<Survey?> surveyProvider = StreamProvider<Survey?>((ref) {
  final String? tenantId = _watchTenantId(ref);
  final String? uid = _watchUid(ref);
  if (tenantId == null || uid == null) {
    return Stream<Survey?>.value(null);
  }
  return ref.watch(strategicRepositoryProvider).watchActiveSurvey(
        tenantId,
        uid,
      );
});
