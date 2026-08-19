import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aurora_backdrop.dart';
import '../../../core/widgets/elytron_logo.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/user_role.dart';
import 'persona_visuals.dart';

/// Tela de boas-vindas do Elytron Dash2Board.
///
/// Objetivo de negócio: em menos de 10 segundos o executivo de segurança
/// entende (1) que produto é este, (2) que ele foi feito para o nível de
/// decisão dele, e (3) o que fazer em seguida.
///
/// Decisões de UX:
/// * Um único CTA primário. Tudo o mais é secundário ou informativo.
/// * As três personas aparecem como *prova de escopo*, não como seletor de
///   permissão - o papel real vem dos custom claims após o login.
/// * Entrada escalonada e discreta; respeita "reduzir movimento".
/// * Largura de conteúdo limitada em telas grandes para não esticar o texto.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(theme.brightness),
      child: Scaffold(
        body: AuroraBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxHeight < 720;
                return Column(
                  children: <Widget>[
                    _TopBar(
                      themeMode: themeMode,
                      onToggleTheme: () =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.sm,
                          AppSpacing.xl,
                          AppSpacing.xl,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxContentWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                _Fade(
                                  controller: _entrance,
                                  start: 0,
                                  child: _Brand(compact: compact),
                                ),
                                SizedBox(
                                  height: compact
                                      ? AppSpacing.xl
                                      : AppSpacing.xxxl,
                                ),
                                _Fade(
                                  controller: _entrance,
                                  start: 0.12,
                                  child: _Headline(compact: compact),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _Fade(
                                  controller: _entrance,
                                  start: 0.24,
                                  child: const _PersonaShowcase(),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _Fade(
                                  controller: _entrance,
                                  start: 0.40,
                                  child: const _Actions(),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _Fade(
                                  controller: _entrance,
                                  start: 0.55,
                                  child: _Footer(scheme: scheme),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Blocos da tela
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.themeMode, required this.onToggleTheme});

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Tooltip(
            message: isDark ? 'Usar tema claro' : 'Usar tema escuro',
            child: IconButton(
              onPressed: onToggleTheme,
              iconSize: 20,
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(
                  scheme.surfaceContainer.withValues(alpha: 0.6),
                ),
                shape: const WidgetStatePropertyAll<OutlinedBorder>(
                  CircleBorder(),
                ),
                minimumSize: const WidgetStatePropertyAll<Size>(Size(44, 44)),
              ),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ElytronLogo(size: compact ? 64 : 84),
        const SizedBox(height: AppSpacing.lg),
        ElytronWordmark(compact: compact),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'A decisão de segurança\nem uma única tela.',
            style: (compact
                    ? theme.textTheme.displaySmall
                    : theme.textTheme.displayMedium)
                ?.copyWith(color: scheme.onSurface),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Relatórios, tendências, insights e pesquisas de cibersegurança, '
          'privacidade e risco — traduzidos para o nível de quem decide.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Vitrine das três personas atendidas pelo produto.
class _PersonaShowcase extends StatefulWidget {
  const _PersonaShowcase();

  @override
  State<_PersonaShowcase> createState() => _PersonaShowcaseState();
}

class _PersonaShowcaseState extends State<_PersonaShowcase> {
  static const List<UserRole> _personas = <UserRole>[
    UserRole.operational,
    UserRole.strategic,
    UserRole.board,
  ];

  int _selected = 1; // CISO em destaque: é o público primário do produto.

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final UserRole active = _personas[_selected];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'FEITO PARA TRÊS NÍVEIS DE DECISÃO',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            for (int i = 0; i < _personas.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PersonaTab(
                  role: _personas[i],
                  selected: i == _selected,
                  onTap: () => setState(() => _selected = i),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSize(
          duration: AppDuration.normal,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: SurfaceCard(
            key: ValueKey<UserRole>(active),
            accent: active.accent,
            semanticLabel: 'Entregas do painel ${active.label}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(active.icon, size: 20, color: active.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        active.label,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  active.audienceTag,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: active.accent.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  active.valueProposition,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final String item in active.highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonaTab extends StatelessWidget {
  const _PersonaTab({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Ver o painel de ${role.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.buttonRadius,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.buttonRadius,
            color: selected
                ? role.accent.withValues(alpha: 0.14)
                : scheme.surfaceContainerLow.withValues(alpha: 0.65),
            border: Border.all(
              color: selected
                  ? role.accent.withValues(alpha: 0.75)
                  : scheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                role.icon,
                size: 18,
                color: selected ? role.accent : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                role.shortLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          onPressed: () => context.go(AppRoute.signIn),
          icon: const Icon(Icons.lock_outline, size: 20),
          label: const Text('Entrar com e-mail corporativo'),
        ),
        if (AppConfig.ssoEnabled) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoute.signIn),
            icon: const Icon(Icons.badge_outlined, size: 20),
            label: const Text('Entrar com SSO da minha empresa'),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Acesso restrito a contas corporativas autorizadas',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        Divider(color: scheme.outlineVariant, height: AppSpacing.xxl),
        Text(
          'Dados tratados conforme a LGPD. Este aplicativo não armazena '
          'conteúdo sensível no dispositivo.',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${AppConfig.companyName} · ${AppConfig.environment.toUpperCase()}',
          textAlign: TextAlign.center,
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Animação de entrada escalonada
// ---------------------------------------------------------------------------

class _Fade extends StatelessWidget {
  const _Fade({
    required this.controller,
    required this.start,
    required this.child,
  });

  final AnimationController controller;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final double end = math.min<double>(1, start + 0.45);
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? inner) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - animation.value)),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }
}
