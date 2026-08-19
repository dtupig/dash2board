import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/strategic/data/mock_strategic_repository.dart';
import 'package:elytron_dash2board/features/strategic/data/strategic_providers.dart';
import 'package:elytron_dash2board/features/strategic/data/strategic_repository.dart';
import 'package:elytron_dash2board/features/strategic/domain/compliance_control.dart';
import 'package:elytron_dash2board/features/strategic/domain/insight_item.dart';
import 'package:elytron_dash2board/features/strategic/domain/posture_index.dart';
import 'package:elytron_dash2board/features/strategic/domain/posture_snapshot.dart';
import 'package:elytron_dash2board/features/strategic/domain/risk_item.dart';
import 'package:elytron_dash2board/features/strategic/domain/survey.dart';
import 'package:elytron_dash2board/features/strategic/domain/tenant_profile.dart';
import 'package:elytron_dash2board/features/strategic/presentation/executive_briefing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Delega tudo para [MockStrategicRepository], exceto o histórico de
/// postura, forçado vazio - usado para testar o estado de dado insuficiente
/// sem precisar reescrever o resto do dataset de demonstração.
class _EmptyHistoryStrategicRepository implements StrategicRepository {
  _EmptyHistoryStrategicRepository(this._inner);

  final StrategicRepository _inner;

  @override
  Stream<List<PostureSnapshot>> watchPostureHistory(
    String tenantId, {
    int months = 12,
  }) {
    return Stream<List<PostureSnapshot>>.value(const <PostureSnapshot>[]);
  }

  @override
  Stream<PostureIndex> watchPostureIndex(String tenantId) =>
      _inner.watchPostureIndex(tenantId);

  @override
  Stream<List<ComplianceControl>> watchCompliance(
    String tenantId, {
    ComplianceFramework? framework,
  }) =>
      _inner.watchCompliance(tenantId, framework: framework);

  @override
  Stream<List<RiskItem>> watchTopRisks(String tenantId, {int limit = 5}) =>
      _inner.watchTopRisks(tenantId, limit: limit);

  @override
  Stream<List<RiskItem>> watchAllRisks(String tenantId) =>
      _inner.watchAllRisks(tenantId);

  @override
  Stream<TenantProfile> watchTenantProfile(String tenantId) =>
      _inner.watchTenantProfile(tenantId);

  @override
  Future<void> recordRiskDecision({
    required String tenantId,
    required String riskId,
    required RiskAcceptance decision,
    required String actorUid,
    required String boardNote,
  }) =>
      _inner.recordRiskDecision(
        tenantId: tenantId,
        riskId: riskId,
        decision: decision,
        actorUid: actorUid,
        boardNote: boardNote,
      );

  @override
  Stream<List<InsightItem>> watchInsights(String tenantId, {int limit = 10}) =>
      _inner.watchInsights(tenantId, limit: limit);

  @override
  Stream<Survey?> watchActiveSurvey(String tenantId, String uid) =>
      _inner.watchActiveSurvey(tenantId, uid);

  @override
  Future<void> submitSurveyResponse({
    required String tenantId,
    required String surveyId,
    required String uid,
    required Map<String, String> answers,
  }) =>
      _inner.submitSurveyResponse(
        tenantId: tenantId,
        surveyId: surveyId,
        uid: uid,
        answers: answers,
      );
}

/// `ChartFrame`/`ChartLoading` animam - nunca `pumpAndSettle` aqui.
void main() {
  const AppUser testUser = AppUser(
    uid: 'ciso-demo',
    email: 'ciso@demo.elytron',
    role: UserRole.strategic,
    tenantId: 'tenant-demo',
  );

  Widget harness(StrategicRepository repository) {
    return ProviderScope(
      overrides: [
        appUserProvider.overrideWith(
          (Ref ref) => Stream<AppUser?>.value(testUser),
        ),
        strategicRepositoryProvider.overrideWith((Ref ref) => repository),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const ExecutiveBriefingScreen(),
      ),
    );
  }

  const Duration loadDelay = Duration(milliseconds: 500);

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'com os dados do mock, mostra índice 72, variação +8 e os dois domínios '
    'mais fracos',
    (WidgetTester tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(harness(MockStrategicRepository()));
      await tester.pump(loadDelay);

      expect(find.textContaining('72'), findsWidgets);
      expect(find.textContaining('+8 pontos'), findsOneWidget);
      expect(
        find.textContaining('Terceiros', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Segurança de Aplicações', findRichText: true),
        findsWidgets,
      );
    },
  );

  testWidgets('com histórico de postura vazio, mostra o estado de dado insuficiente', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      harness(_EmptyHistoryStrategicRepository(MockStrategicRepository())),
    );
    await tester.pump(loadDelay);

    expect(
      find.text('Ainda não é possível gerar o briefing'),
      findsOneWidget,
    );
    expect(find.text('Compartilhar PDF'), findsNothing);
  });
}
