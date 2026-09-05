import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/shell/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Testa `HomeShell` isolado do app real - um `GoRouter` com 5 branches
/// mínimos (mesma forma de `router_shell_branches.dart`: 3 painéis + 2
/// destinos fixos), cada um com um `TextField` próprio, para provar que
/// trocar de aba preserva o estado do branch anterior (critério de
/// aceite de HU-W-02: "nenhum estado de tela é perdido").
void main() {
  const AppUser strategicUser = AppUser(
    uid: 'ciso-demo',
    email: 'ciso@demo.elytron',
    role: UserRole.strategic,
    tenantId: 'tenant-demo',
  );

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/estrategia',
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell shell,
          ) =>
              HomeShell(
            navigationShell: shell,
            servicesBranch: 3,
            reportsBranch: 4,
          ),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/operacao',
                  builder: (_, __) => const _BranchScreen('Operação'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/estrategia',
                  builder: (_, __) => const _BranchScreen('Estratégia'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/board',
                  builder: (_, __) => const _BranchScreen('Board'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/servicos',
                  builder: (_, __) => const _BranchScreen('Serviços'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/relatorios',
                  builder: (_, __) => const _BranchScreen('Relatórios'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget harness(GoRouter router) {
    return ProviderScope(
      overrides: [
        appUserProvider.overrideWith(
          (Ref ref) => Stream<AppUser?>.value(strategicUser),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  void setLogicalSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('compact mostra NavigationBar com o painel do papel selecionado',
      (
    WidgetTester tester,
  ) async {
    setLogicalSize(tester, const Size(390, 844));

    await tester.pumpWidget(harness(buildRouter()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    final NavigationBar bar = tester.widget(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Estratégia'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('large mostra NavigationRail expandido, com rótulos', (
    WidgetTester tester,
  ) async {
    setLogicalSize(tester, const Size(1400, 900));

    await tester.pumpWidget(harness(buildRouter()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(NavigationRail), findsOneWidget);
    final NavigationRail rail = tester.widget(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
  });

  testWidgets('medium mostra NavigationRail recolhido, sem rótulo extenso', (
    WidgetTester tester,
  ) async {
    setLogicalSize(tester, const Size(700, 900));

    await tester.pumpWidget(harness(buildRouter()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(NavigationRail), findsOneWidget);
    final NavigationRail rail = tester.widget(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
  });

  testWidgets(
    'trocar para Serviços e voltar ao Painel preserva o texto digitado',
    (WidgetTester tester) async {
      setLogicalSize(tester, const Size(1400, 900));

      await tester.pumpWidget(harness(buildRouter()));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byType(TextField), 'rascunho não salvo');
      await tester.pump();
      expect(find.text('rascunho não salvo'), findsOneWidget);

      // Índice 1 = Serviços (visibleBranches[1]), na navegação visível.
      await tester.tap(find.text('Serviços'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Serviços'), findsWidgets);
      expect(find.text('rascunho não salvo'), findsNothing);

      // Índice 0 = Painel do papel (Estratégia, para o `strategicUser`).
      await tester.tap(find.text('Painel'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.text('rascunho não salvo'),
        findsOneWidget,
        reason: 'o branch de Estratégia não deveria ter sido reconstruído',
      );
    },
  );
}

class _BranchScreen extends StatelessWidget {
  const _BranchScreen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(decoration: InputDecoration(labelText: label)),
      ),
    );
  }
}
