import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/layout/breakpoints.dart';
import '../auth/domain/user_role.dart';
import '../auth/presentation/persona_visuals.dart';

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
class HomeShell extends ConsumerWidget {
  const HomeShell({
    super.key,
    required this.navigationShell,
    required this.servicesBranch,
    required this.reportsBranch,
  });

  final StatefulNavigationShell navigationShell;
  final int servicesBranch;
  final int reportsBranch;

  static int _homeBranchFor(UserRole role) => switch (role) {
        UserRole.operational => 0,
        UserRole.strategic => 1,
        UserRole.board => 2,
        UserRole.pending => 0,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserRole role =
        ref.watch(appUserProvider).value?.role ?? UserRole.pending;
    final List<int> visibleBranches = <int>[
      _homeBranchFor(role),
      servicesBranch,
      reportsBranch,
    ];
    final List<_Destination> destinations = <_Destination>[
      _Destination(icon: role.icon, label: 'Painel'),
      const _Destination(
        icon: Icons.miscellaneous_services_outlined,
        label: 'Serviços',
      ),
      const _Destination(
        icon: Icons.folder_copy_outlined,
        label: 'Relatórios',
      ),
    ];

    final int matched = visibleBranches.indexOf(navigationShell.currentIndex);
    final int selectedIndex = matched < 0 ? 0 : matched;

    void onSelect(int index) {
      final int branch = visibleBranches[index];
      navigationShell.goBranch(
        branch,
        initialLocation: branch == navigationShell.currentIndex,
      );
    }

    final LayoutSize size = LayoutSize.of(context);

    if (size == LayoutSize.compact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelect,
          destinations: <Widget>[
            for (final _Destination d in destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            extended: size == LayoutSize.large,
            destinations: <NavigationRailDestination>[
              for (final _Destination d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
