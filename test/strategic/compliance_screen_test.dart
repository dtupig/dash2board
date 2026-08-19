import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/strategic/data/mock_strategic_repository.dart';
import 'package:elytron_dash2board/features/strategic/data/strategic_providers.dart';
import 'package:elytron_dash2board/features/strategic/presentation/compliance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// `ChartFrame`/`ChartLoading` e a revelação de entrada dos gráficos têm
/// animação: nunca `pumpAndSettle` aqui, sempre `pump(Duration)`.
void main() {
  const AppUser testUser = AppUser(
    uid: 'ciso-demo',
    email: 'ciso@demo.elytron',
    role: UserRole.strategic,
    tenantId: 'tenant-demo',
  );

  GoRouter buildRouter({String? framework, String? domain}) {
    final Map<String, String> query = <String, String>{
      if (framework != null) 'framework': framework,
      if (domain != null) 'domain': domain,
    };
    final String initialLocation =
        Uri(path: '/compliance', queryParameters: query.isEmpty ? null : query)
            .toString();

    return GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        GoRoute(
          path: '/compliance',
          builder: (BuildContext context, GoRouterState state) {
            return ComplianceScreen(
              initialFrameworkWire: state.uri.queryParameters['framework'],
              initialDomainWire: state.uri.queryParameters['domain'],
            );
          },
        ),
      ],
    );
  }

  Widget harness({String? framework, String? domain}) {
    return ProviderScope(
      overrides: [
        appUserProvider.overrideWith(
          (Ref ref) => Stream<AppUser?>.value(testUser),
        ),
        strategicRepositoryProvider.overrideWith(
          (Ref ref) => MockStrategicRepository(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: buildRouter(framework: framework, domain: domain),
      ),
    );
  }

  const Duration loadDelay = Duration(milliseconds: 500);

  /// A tela é mais alta que a viewport padrão de teste (800x600): sem isso,
  /// controles no fim da lista nunca ficam visíveis para `tap()`/`find`.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('os quatro frameworks aparecem', (WidgetTester tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(loadDelay);

    expect(find.text('ISO 27001'), findsWidgets);
    expect(find.text('NIST CSF'), findsWidgets);
    expect(find.text('LGPD'), findsWidgets);
    expect(find.text('PCI DSS'), findsWidgets);
  });

  testWidgets('filtrar por gap reduz a lista e a contagem bate', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(loadDelay);

    // Antes do filtro: controle conforme (A.5.1) e controle em lacuna
    // (A.12.6) aparecem os dois.
    expect(find.text('A.5.1'), findsOneWidget);
    expect(find.text('A.12.6'), findsOneWidget);

    // `find.text('Lacuna')` sozinho é ambíguo: cada item em lacuna na lista
    // também mostra "Lacuna" no seu `SeverityChip`. O chip de FILTRO é o
    // único dentro de um `FilterChip`, e fica dentro de uma linha com scroll
    // horizontal - por isso `ensureVisible` antes do toque.
    final Finder gapChip = find.widgetWithText(FilterChip, 'Lacuna');
    await tester.ensureVisible(gapChip);
    await tester.pump();
    await tester.tap(gapChip);
    await tester.pump(const Duration(milliseconds: 300));

    // Depois do filtro: só os 5 controles em lacuna do mock permanecem.
    expect(find.text('A.5.1'), findsNothing);
    expect(find.text('A.12.6'), findsOneWidget);
    expect(find.text('DE.CM-8'), findsOneWidget);
    expect(find.text('ID.SC-4'), findsOneWidget);
    expect(find.text('Req.6'), findsOneWidget);
    expect(find.text('Req.12'), findsOneWidget);

    // O cabeçalho de lacunas abertas (calculado sobre o total, não o
    // filtro) já mostrava 5 desde o início.
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('abrir um controle sem evidência mostra o estado vazio de evidência', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(loadDelay);

    // A.12.6 está em lacuna e, no mock, controles em lacuna não têm
    // evidência anexada.
    await tester.tap(find.text('A.12.6'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.textContaining('não tem evidência anexada'),
      findsOneWidget,
    );
  });

  testWidgets('navegar com ?framework=lgpd já abre filtrado', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness(framework: 'LGPD'));
    await tester.pump(loadDelay);

    // Só os 6 controles de LGPD aparecem; um controle de outro framework
    // (ISO 27001) não aparece.
    expect(find.text('Art.6'), findsOneWidget);
    expect(find.text('Art.46'), findsOneWidget);
    expect(find.text('A.5.1'), findsNothing);
  });
}
