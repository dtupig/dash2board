import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/domain/user_role.dart';
import '../features/auth/presentation/pending_access_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/dashboard/presentation/board_dashboard_screen.dart';
import '../features/dashboard/presentation/operational_dashboard_screen.dart';
import '../features/dashboard/presentation/strategic_dashboard_screen.dart';
import '../features/dev/chart_gallery_screen.dart';
import '../features/onboarding/presentation/onboarding_gate.dart';
import '../features/services/presentation/request_inbox_screen.dart';
import '../features/services/presentation/service_catalog_screen.dart';
import '../features/services/presentation/services_hub_screen.dart';
import '../features/services/presentation/wizard/request_wizard_screen.dart';
import '../features/strategic/presentation/compliance_screen.dart';
import '../features/strategic/presentation/executive_briefing_screen.dart';
import '../features/strategic/presentation/insights_screen.dart';
import 'providers.dart';

/// Rotas nomeadas do aplicativo.
abstract final class AppRoute {
  static const String splash = '/';
  static const String welcome = '/boas-vindas';
  static const String signIn = '/entrar';
  static const String pendingAccess = '/aguardando-acesso';
  static const String operational = '/operacao';
  static const String strategic = '/estrategia';
  static const String board = '/board';

  /// Bifurcação do módulo de serviços - relatórios ou demanda de RFS.
  /// Acessível pelas três personas, fora da árvore de nenhum dashboard.
  static const String services = '/servicos';
  static const String servicesCatalog = '/servicos/catalogo';
  static const String servicesInbox = '/servicos/solicitacoes';

  /// Compliance por framework, com evidência - filha de [strategic].
  /// Aceita `?framework=` e `?domain=` para o drill-down do painel.
  static const String strategicCompliance = '/estrategia/compliance';

  /// Feed de insights, tendências e pesquisas - filha de [strategic].
  static const String strategicInsights = '/estrategia/insights';

  /// Briefing executivo de uma página, pronto para compartilhar - filha de
  /// [strategic].
  static const String strategicBriefing = '/estrategia/briefing';

  /// Galeria de gráficos - só existe quando `AppConfig.mockMode` é
  /// verdadeiro. Nunca referenciada fora de contexto de demonstração.
  static const String devChartGallery = '/dev/graficos';

  /// Rotas acessíveis sem sessão autenticada.
  static const Set<String> publicRoutes = <String>{
    splash,
    welcome,
    signIn,
  };

  /// Rotas de "entrada" das quais um usuário já liberado deve sair.
  static const Set<String> entryRoutes = <String>{
    splash,
    welcome,
    signIn,
    pendingAccess,
  };

  static String forRole(UserRole role) => role.landingRoute;
}

/// GoRouter reativo ao estado de autenticação.
///
/// O redirect é a única guarda de navegação do app. Ele é *fail-closed*:
/// enquanto o estado do usuário não estiver resolvido, o usuário fica no
/// splash; qualquer inconsistência leva de volta à tela de boas-vindas.
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
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<AppUser?> snapshot = authState.value;
      final String location = state.matchedLocation;

      // 1. Ainda resolvendo a sessão -> mantém o splash.
      if (snapshot.isLoading) {
        return location == AppRoute.splash ? null : AppRoute.splash;
      }

      // 2. Falha ao resolver a sessão -> volta para a entrada pública.
      final AppUser? user = snapshot.value;
      if (snapshot.hasError || user == null) {
        return AppRoute.publicRoutes.contains(location) &&
                location != AppRoute.splash
            ? null
            : AppRoute.welcome;
      }

      // 3. Autenticado, mas sem papel/tenant provisionado.
      if (!user.canEnterDashboard) {
        return location == AppRoute.pendingAccess
            ? null
            : AppRoute.pendingAccess;
      }

      // 4. Autenticado e liberado: sai das rotas de entrada.
      final String home = AppRoute.forRole(user.role);
      if (AppRoute.entryRoutes.contains(location)) {
        return home;
      }

      // 5. Impede acesso ao dashboard de outra persona - e a QUALQUER rota
      // filha dele (ex.: `/estrategia/compliance`), não só ao path exato.
      // Comparar por prefixo aqui é o que faz o guard valer para subrotas
      // futuras sem precisar listá-las uma a uma.
      const Set<String> dashboards = <String>{
        AppRoute.operational,
        AppRoute.strategic,
        AppRoute.board,
      };
      for (final String dashboard in dashboards) {
        final bool isUnderDashboard =
            location == dashboard || location.startsWith('$dashboard/');
        if (isUnderDashboard && dashboard != home) {
          return home;
        }
      }

      return null;
    },
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
      GoRoute(
        path: AppRoute.operational,
        name: 'operational',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingGate(
          role: UserRole.operational,
          child: OperationalDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.strategic,
        name: 'strategic',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingGate(
          role: UserRole.strategic,
          child: StrategicDashboardScreen(),
        ),
        routes: <RouteBase>[
          GoRoute(
            // Relativo: compõe com o pai para formar
            // `AppRoute.strategicCompliance` ('/estrategia/compliance').
            path: 'compliance',
            name: 'strategicCompliance',
            builder: (BuildContext context, GoRouterState state) {
              return ComplianceScreen(
                initialFrameworkWire: state.uri.queryParameters['framework'],
                initialDomainWire: state.uri.queryParameters['domain'],
              );
            },
          ),
          GoRoute(
            path: 'insights',
            name: 'strategicInsights',
            builder: (BuildContext context, GoRouterState state) =>
                const InsightsScreen(),
          ),
          GoRoute(
            path: 'briefing',
            name: 'strategicBriefing',
            builder: (BuildContext context, GoRouterState state) =>
                const ExecutiveBriefingScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.board,
        name: 'board',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingGate(
          role: UserRole.board,
          child: BoardDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.services,
        name: 'services',
        builder: (BuildContext context, GoRouterState state) =>
            const ServicesHubScreen(),
      ),
      GoRoute(
        path: AppRoute.servicesCatalog,
        name: 'servicesCatalog',
        builder: (BuildContext context, GoRouterState state) =>
            ServiceCatalogScreen(
          mode: CatalogMode.fromWire(state.uri.queryParameters['modo']),
        ),
      ),
      GoRoute(
        path: '/servicos/demanda/:serviceKey',
        name: 'requestWizard',
        builder: (BuildContext context, GoRouterState state) =>
            RequestWizardScreen(
          serviceKey: state.pathParameters['serviceKey']!,
        ),
      ),
      GoRoute(
        path: AppRoute.servicesInbox,
        name: 'servicesInbox',
        builder: (BuildContext context, GoRouterState state) =>
            const RequestInboxScreen(),
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
