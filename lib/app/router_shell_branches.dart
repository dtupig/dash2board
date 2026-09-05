import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/user_role.dart';
import '../features/dashboard/presentation/board_dashboard_screen.dart';
import '../features/dashboard/presentation/operational_dashboard_screen.dart';
import '../features/dashboard/presentation/strategic_dashboard_screen.dart';
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

/// Os 5 branches do `StatefulShellRoute` da casca de navegação (HU-W-02),
/// cada um com seu próprio `Navigator`/estado preservado ao trocar de aba -
/// os 3 painéis das personas, serviços e relatórios. Isolado de
/// `router.dart` para manter aquele arquivo abaixo do limite de 250 linhas.
///
/// A ordem aqui é a mesma que `HomeShell._homeBranchFor`/`_servicesBranch`/
/// `_reportsBranch` (`lib/features/shell/home_shell.dart`) assume por
/// índice - mudar a ordem exige mudar os dois lugares juntos.
List<StatefulShellBranch> buildHomeShellBranches() {
  return <StatefulShellBranch>[
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.operational,
          name: 'operational',
          builder: (BuildContext context, GoRouterState state) =>
              const OnboardingGate(
            role: UserRole.operational,
            child: OperationalDashboardScreen(),
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
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
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.board,
          name: 'board',
          builder: (BuildContext context, GoRouterState state) =>
              const OnboardingGate(
            role: UserRole.board,
            child: BoardDashboardScreen(),
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.services,
          name: 'services',
          builder: (BuildContext context, GoRouterState state) =>
              const ServicesHubScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'catalogo',
              name: 'servicesCatalog',
              builder: (BuildContext context, GoRouterState state) =>
                  ServiceCatalogScreen(
                mode: CatalogMode.fromWire(state.uri.queryParameters['modo']),
              ),
            ),
            GoRoute(
              path: 'demanda/:serviceKey',
              name: 'requestWizard',
              builder: (BuildContext context, GoRouterState state) =>
                  RequestWizardScreen(
                serviceKey: state.pathParameters['serviceKey']!,
              ),
            ),
            GoRoute(
              path: 'solicitacoes',
              name: 'servicesInbox',
              builder: (BuildContext context, GoRouterState state) =>
                  const RequestInboxScreen(),
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.reportsList,
          name: 'reportsList',
          builder: (BuildContext context, GoRouterState state) =>
              const ReportsListScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: ':reportId',
              name: 'reportViewer',
              builder: (BuildContext context, GoRouterState state) =>
                  ReportViewerScreen(
                reportId: state.pathParameters['reportId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}
