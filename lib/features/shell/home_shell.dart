import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/layout/breakpoints.dart';
import '../auth/domain/app_user.dart';
import '../auth/domain/user_role.dart';
import '../auth/presentation/persona_visuals.dart';
import '../auth/presentation/sign_in_controller.dart';
import 'web_sidebar.dart';

/// Casca de navegação persistente das 3 personas (HU-W-02).
///
/// `compact` (`<600`): barra inferior. `medium`/`expanded` (`600-1199`):
/// `NavigationRail` recolhido, só ícone. `large` (`>=1200`): rail expandido,
/// com rótulo - limiares de P-8 do épico E-W (`docs/19_HISTORIAS_INTERFACE_WEB.md`).
///
/// [navigationShell] tem 5 branches (os 3 painéis + serviços + relatórios,
/// ver `router_shell_branches.dart`), mas só 3 destinos aparecem na
/// navegação visível: o painel do papel do usuário, serviços e relatórios -
/// os outros 2 painéis nunca são alcançáveis por esse usuário (mesma
/// guarda de `router_redirect.dart`), então não teria sentido mostrá-los.
/// [servicesBranch]/[reportsBranch] identificam quais dos 5 branches são
/// esses dois destinos fixos - o índice de cada painel é implícito na
/// ordem de [UserRole] (`operational` 0, `strategic` 1, `board` 2), a
/// mesma ordem em que `router_shell_branches.dart` declara os 3 primeiros
/// branches.
///
/// [state] é usado só para ler `?acessoNegado=1` (HU-W-03): quando um link
/// tenta abrir o dashboard de outra persona, `router_redirect.dart` bate o
/// usuário de volta ao próprio painel com esse parâmetro, e aqui mostramos
/// a negativa explícita exigida - "nunca conteúdo parcial nem tela em
/// branco" - antes de removê-lo da URL.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({
    super.key,
    required this.state,
    required this.navigationShell,
    required this.servicesBranch,
    required this.reportsBranch,
  });

  final GoRouterState state;
  final StatefulNavigationShell navigationShell;
  final int servicesBranch;
  final int reportsBranch;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _accessDeniedHandled = false;

  static int _homeBranchFor(UserRole role) => switch (role) {
        UserRole.operational => 0,
        UserRole.strategic => 1,
        UserRole.board => 2,
        UserRole.pending => 0,
      };

  @override
  Widget build(BuildContext context) {
    if (widget.state.uri.queryParameters['acessoNegado'] == '1' &&
        !_accessDeniedHandled) {
      _accessDeniedHandled = true;
      final String cleanPath = widget.state.uri.path;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Esse link não é para o seu perfil. Voltamos ao seu painel.',
            ),
          ),
        );
        GoRouter.of(context).go(cleanPath);
      });
    }

    final AppUser? user = ref.watch(appUserProvider).value;
    final UserRole role = user?.role ?? UserRole.pending;
    final List<int> visibleBranches = <int>[
      _homeBranchFor(role),
      widget.servicesBranch,
      widget.reportsBranch,
    ];
    final List<SidebarDestination> destinations = <SidebarDestination>[
      SidebarDestination(icon: role.icon, label: 'Painel'),
      const SidebarDestination(
        icon: Icons.miscellaneous_services_outlined,
        label: 'Serviços',
      ),
      const SidebarDestination(
        icon: Icons.folder_copy_outlined,
        label: 'Relatórios',
      ),
    ];

    final int matched =
        visibleBranches.indexOf(widget.navigationShell.currentIndex);
    final int selectedIndex = matched < 0 ? 0 : matched;

    void onSelect(int index) {
      final int branch = visibleBranches[index];
      widget.navigationShell.goBranch(
        branch,
        initialLocation: branch == widget.navigationShell.currentIndex,
      );
    }

    void signOut() =>
        unawaited(ref.read(signInControllerProvider.notifier).signOut());

    final LayoutSize size = LayoutSize.of(context);

    if (size == LayoutSize.compact) {
      return Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelect,
          destinations: <Widget>[
            for (final SidebarDestination d in destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: <Widget>[
          WebSidebar(
            role: role,
            userName: user?.firstName ?? 'executivo',
            extended: size == LayoutSize.large,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            destinations: destinations,
            onSignOut: signOut,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }
}
