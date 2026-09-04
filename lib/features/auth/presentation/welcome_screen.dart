import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aurora_backdrop.dart';
import '../../../core/widgets/elytron_logo.dart';
import 'widgets/welcome_actions_footer.dart';
import 'widgets/welcome_fade.dart';
import 'widgets/welcome_persona_showcase.dart';
import 'widgets/welcome_top_bar.dart';

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
///
/// Os blocos visuais (barra superior, vitrine de personas, CTAs, rodapé e a
/// animação de entrada) vivem em `widgets/welcome_*.dart`, para manter este
/// arquivo abaixo do limite de 250 linhas.
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
                    WelcomeTopBar(
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
                                WelcomeFade(
                                  controller: _entrance,
                                  start: 0,
                                  child: _Brand(compact: compact),
                                ),
                                SizedBox(
                                  height:
                                      compact ? AppSpacing.xl : AppSpacing.xxxl,
                                ),
                                WelcomeFade(
                                  controller: _entrance,
                                  start: 0.12,
                                  child: _Headline(compact: compact),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                WelcomeFade(
                                  controller: _entrance,
                                  start: 0.24,
                                  child: const PersonaShowcase(),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                WelcomeFade(
                                  controller: _entrance,
                                  start: 0.40,
                                  child: const WelcomeActions(),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                WelcomeFade(
                                  controller: _entrance,
                                  start: 0.55,
                                  child: WelcomeFooter(scheme: scheme),
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
