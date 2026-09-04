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
import '../features/reports/presentation/report_viewer_screen.dart';
import '../features/reports/presentation/reports_list_screen.dart';
import '../features/services/presentation/request_inbox_screen.dart';
import '../features/services/presentation/service_catalog_screen.dart';
import '../features/services/presentation/services_hub_screen.dart';
import '../features/services/presentation/wizard/request_wizard_screen.dart';
import '../features/strategic/presentation/compliance_screen.dart';
import '../features/strategic/presentation/executive_briefing_screen.dart';
import '../features/strategic/presentation/insights_screen.dart';
import 'app_route.dart';
import 'providers.dart';
import 'router_redirect.dart';

export 'app_route.dart' show AppRoute;

/// GoRouter reativo ao estado de autenticação.
///
/// As rotas nomeadas vivem em `app_route.dart` e a guarda de navegação em
/// `router_redirect.dart`, ambos reexportados/usados aqui, para manter este
/// arquivo abaixo do limite de 250 linhas.
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
      GoRoute(
        path: AppRoute.reportsList,
        name: 'reportsList',
        builder: (BuildContext context, GoRouterState state) =>
            const ReportsListScreen(),
      ),
      GoRoute(
        path: '/relatorios/:reportId',
        name: 'reportViewer',
        builder: (BuildContext context, GoRouterState state) =>
            ReportViewerScreen(
          reportId: state.pathParameters['reportId']!,
        ),
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
