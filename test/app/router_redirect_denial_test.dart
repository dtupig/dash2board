import 'package:elytron_dash2board/app/app_route.dart';
import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/app/router_redirect.dart';
import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/shell/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// HU-W-03, critério "link para tela sem permissão": abrir o dashboard de
/// outra persona nunca pode render conteúdo parcial nem tela em branco -
/// tem que ter negativa explícita e voltar ao próprio painel. Usa a
/// guarda real (`buildRedirect`) e o `HomeShell` real, com telas de branch
/// mínimas (o mesmo molde de `test/shell/home_shell_test.dart`) para não
/// depender dos provedores de dado de cada dashboard de verdade.
void main() {
  const AppUser strategicUser = AppUser(
    uid: 'ciso-demo',
    email: 'ciso@demo.elytron',
    role: UserRole.strategic,
    tenantId: 'tenant-demo',
  );

  const String deniedMessage =
      'Esse link não é para o seu perfil. Voltamos ao seu painel.';

  GoRouter buildRouter(String initialLocation) {
    final ValueNotifier<AsyncValue<AppUser?>> authState =
        ValueNotifier<AsyncValue<AppUser?>>(
      const AsyncValue<AppUser?>.data(strategicUser),
    );

    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: authState,
      redirect: buildRedirect(authState),
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell shell,
          ) =>
              HomeShell(
            state: state,
            navigationShell: shell,
            servicesBranch: 3,
            reportsBranch: 4,
          ),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoute.operational,
                  builder: (_, __) => const _Screen('Operação'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoute.strategic,
                  builder: (_, __) => const _Screen('Estratégia'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoute.board,
                  builder: (_, __) => const _Screen('Board'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoute.services,
                  builder: (_, __) => const _Screen('Serviços'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoute.reportsList,
                  builder: (_, __) => const _Screen('Relatórios'),
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

  testWidgets(
    'link para o painel de outra persona: negativa explícita e volta ao '
    'próprio painel, nunca tela em branco',
    (WidgetTester tester) async {
      final GoRouter router = buildRouter(AppRoute.board);

      await tester.pumpWidget(harness(router));
      await tester.pump(const Duration(milliseconds: 50));

      // Nunca conteúdo parcial nem tela em branco: caiu no próprio painel.
      expect(find.widgetWithText(AppBar, 'Estratégia'), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Board'), findsNothing);

      // Negativa explícita, não um redirecionamento silencioso.
      await tester.pump();
      expect(find.text(deniedMessage), findsOneWidget);
    },
  );

  testWidgets(
    'uma segunda tentativa de link indevido mostra a negativa de novo',
    (WidgetTester tester) async {
      final GoRouter router = buildRouter(AppRoute.strategic);

      await tester.pumpWidget(harness(router));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(deniedMessage), findsNothing);

      router.go(AppRoute.operational);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.widgetWithText(AppBar, 'Estratégia'), findsOneWidget);
      expect(find.text(deniedMessage), findsOneWidget);
    },
  );

  testWidgets(
    'link direto para o próprio painel não mostra negativa nenhuma',
    (WidgetTester tester) async {
      final GoRouter router = buildRouter(AppRoute.strategic);

      await tester.pumpWidget(harness(router));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.widgetWithText(AppBar, 'Estratégia'), findsOneWidget);
      expect(find.text(deniedMessage), findsNothing);
    },
  );
}

class _Screen extends StatelessWidget {
  const _Screen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(label)));
  }
}
