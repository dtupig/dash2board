import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/dashboard/presentation/strategic_dashboard_screen.dart';
import 'package:elytron_dash2board/features/strategic/data/mock_strategic_repository.dart';
import 'package:elytron_dash2board/features/strategic/data/strategic_providers.dart';
import 'package:elytron_dash2board/features/strategic/domain/posture_index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositório que falha só no índice de postura - permite testar que o
/// bloco de erro aparece sem derrubar os outros blocos, que consomem
/// providers diferentes (cada bloco resolve seu próprio `AsyncValue`).
class _PostureIndexFailingRepository extends MockStrategicRepository {
  @override
  Stream<PostureIndex> watchPostureIndex(String tenantId) {
    return Stream<PostureIndex>.error(Exception('falha simulada'));
  }
}

void main() {
  const AppUser testUser = AppUser(
    uid: 'ciso-demo',
    email: 'ciso@demo.elytron',
    role: UserRole.strategic,
    tenantId: 'tenant-demo',
  );

  const Duration loadDelay = Duration(milliseconds: 500);

  Widget harness({required MockStrategicRepository repository}) {
    return ProviderScope(
      overrides: [
        appUserProvider.overrideWith(
          (Ref ref) => Stream<AppUser?>.value(testUser),
        ),
        strategicRepositoryProvider.overrideWith((Ref ref) => repository),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const StrategicDashboardScreen(),
      ),
    );
  }

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('renderiza o índice 72 e a variação de +8 em 12 meses', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness(repository: MockStrategicRepository()));
    await tester.pump(loadDelay);

    expect(find.text('72'), findsOneWidget);
    expect(find.textContaining('+8'), findsOneWidget);
  });

  testWidgets('renderiza as seis barras de domínio, pior primeiro', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness(repository: MockStrategicRepository()));
    await tester.pump(loadDelay);

    const List<String> domainLabelsInAscendingScoreOrder = <String>[
      'Terceiros', // 55 - o pior, aparece primeiro
      'Segurança de Aplicações', // 58
      'Nuvem', // 63
      'Dados', // 74
      'Endpoint', // 76
      'Identidade e Acesso', // 81 - o melhor, aparece por último
    ];

    final List<String> labelsInOrder = <String>[];
    for (final Element element in tester.elementList(find.byType(Text))) {
      final Text widget = element.widget as Text;
      if (widget.data != null &&
          domainLabelsInAscendingScoreOrder.contains(widget.data)) {
        labelsInOrder.add(widget.data!);
      }
    }

    expect(labelsInOrder, domainLabelsInAscendingScoreOrder);
  });

  testWidgets('estado de erro do índice de postura exibe "tentar de novo"', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      harness(repository: _PostureIndexFailingRepository()),
    );
    await tester.pump(loadDelay);

    expect(
      find.widgetWithText(OutlinedButton, 'Tentar de novo'),
      findsWidgets,
    );
    // Os outros blocos, que não dependem do índice de postura, continuam
    // resolvendo normalmente - a tela não vira uma tela de erro só porque um
    // provider falhou.
    expect(find.text('Top riscos de negócio'), findsOneWidget);
  });
}
