import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/presentation/pending_access_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/dev/chart_gallery_screen.dart';
import '../features/shell/home_shell.dart';
import 'app_route.dart';
import 'providers.dart';
import 'router_redirect.dart';
import 'router_shell_branches.dart';

export 'app_route.dart' show AppRoute;

/// GoRouter reativo ao estado de autenticação.
///
/// As rotas nomeadas vivem em `app_route.dart`, a guarda de navegação em
/// `router_redirect.dart` e os branches da casca de navegação persistente
/// (HU-W-02) em `router_shell_branches.dart` - todos usados aqui, para
/// manter este arquivo abaixo do limite de 250 linhas.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final ValueNotifier<AsyncValue<AppUser?>> authState =
      ValueNotifier<AsyncValue<AppUser?>>(const AsyncValue<AppUser?>.loading());

  ref.listen<AsyncValue<AppUser?>>(
    appUserProvider,
    (AsyncValue<AppUser?>? previous, AsyncValue<AppUser?> next) {
      authState.value = next;
    },
    fireImmediately: true,
  );

  ref.onDispose(authState.dispose);

  return GoRouter(
    initialLocation: AppRoute.splash,
    refreshListenable: authState,
    redirect: buildRedirect(authState),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.splash,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.welcome,
        name: 'welcome',
        builder: (BuildContext context, GoRouterState state) =>
            const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoute.signIn,
        name: 'signIn',
        builder: (BuildContext context, GoRouterState state) =>
            const SignInScreen(),
      ),
      GoRoute(
        path: AppRoute.pendingAccess,
        name: 'pendingAccess',
        builder: (BuildContext context, GoRouterState state) =>
            const PendingAccessScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) =>
            HomeShell(
          navigationShell: navigationShell,
          // Os índices dos 2 últimos branches declarados por
          // `buildHomeShellBranches()` - os 3 primeiros são os painéis,
          // na ordem operational/strategic/board que `HomeShell` assume.
          servicesBranch: 3,
          reportsBranch: 4,
        ),
        branches: buildHomeShellBranches(),
      ),
      // Só existe em modo de demonstração: nenhum build de produção enxerga
      // esta rota, mesmo lendo o código-fonte publicado.
      if (AppConfig.mockMode)
        GoRoute(
          path: AppRoute.devChartGallery,
          name: 'devChartGallery',
          builder: (BuildContext context, GoRouterState state) =>
              const ChartGalleryScreen(),
        ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Rota não encontrada: ${state.uri}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    ),
  );
});
