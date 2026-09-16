import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/elytron_logo.dart';
import '../auth/domain/user_role.dart';
import '../auth/presentation/persona_visuals.dart';

/// Um destino da [WebSidebar] - mesmo par ícone/rótulo que
/// `HomeShell._Destination`, só que exposto para fora do arquivo.
class SidebarDestination {
  const SidebarDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Sidebar de `medium`/`expanded`/`large` (HU-W-02), estilizada conforme a
/// Fase 1 do épico E-W (`Dash2Board Web.dc.html`): logo + saudação + papel
/// no topo, item ativo com pílula tintada na cor de acento da persona,
/// "Sair" fixo embaixo. `extended` decide entre recolhida (só ícone,
/// `medium`/`expanded`) e expandida (com rótulo, `large`) - mesma máquina
/// de estado do `NavigationRail` que ela envolve, só a pele muda.
class WebSidebar extends StatelessWidget {
  const WebSidebar({
    super.key,
    required this.role,
    required this.userName,
    required this.extended,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.onSignOut,
  });

  final UserRole role;
  final String userName;
  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SidebarDestination> destinations;
  final VoidCallback onSignOut;

  /// Largura expandida (`large`) - mesmo valor do mockup web da Fase 1.
  /// `leading`/`trailing` do `NavigationRail` recebem largura irrestrita
  /// (não a largura real da trilha), então quem precisa desenhar uma borda
  /// de ponta a ponta usa este valor para se limitar, em vez de
  /// `width: double.infinity` (que quebra o layout com constraint
  /// infinita).
  static const double extendedWidth = 232;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return NavigationRail(
      backgroundColor: scheme.surfaceContainerLow,
      extended: extended,
      minWidth: 72,
      minExtendedWidth: extendedWidth,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      useIndicator: true,
      indicatorColor: role.accent.withValues(alpha: 0.14),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      selectedIconTheme: IconThemeData(color: role.accent, size: 18),
      unselectedIconTheme: IconThemeData(
        color: scheme.onSurfaceVariant,
        size: 18,
      ),
      selectedLabelTextStyle: theme.textTheme.titleMedium?.copyWith(
        color: role.accent,
      ),
      unselectedLabelTextStyle: theme.textTheme.titleMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      leading:
          _SidebarHeader(extended: extended, role: role, userName: userName),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: _SignOutItem(extended: extended, onTap: onSignOut),
        ),
      ),
      destinations: <NavigationRailDestination>[
        for (final SidebarDestination d in destinations)
          NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
      ],
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.extended,
    required this.role,
    required this.userName,
  });

  final bool extended;
  final UserRole role;
  final String userName;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: ElytronLogo(size: 28, showGlow: false),
      );
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const ElytronLogo(size: 30, showGlow: false),
              const SizedBox(width: AppSpacing.sm),
              Text('Dash2Board', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: WebSidebar.extendedWidth,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: scheme.outline)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Olá, $userName', style: theme.textTheme.titleMedium),
                  Text(
                    role.shortLabel.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: role.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutItem extends StatelessWidget {
  const _SignOutItem({required this.extended, required this.onTap});

  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (!extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: IconButton(
          tooltip: 'Sair',
          onPressed: onTap,
          icon: Icon(
            Icons.logout,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: WebSidebar.extendedWidth),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.logout, size: 17, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Sair',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
