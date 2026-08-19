import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/elytron_logo.dart';
import '../auth/domain/app_user.dart';
import '../auth/domain/user_role.dart';
import '../auth/presentation/persona_visuals.dart';
import '../auth/presentation/sign_in_controller.dart';

/// Casca comum dos três dashboards.
///
/// Mantém cabeçalho, saudação, identidade da persona e ações de conta
/// idênticas entre os painéis - o que muda é apenas o conteúdo.
class PersonaScaffold extends ConsumerWidget {
  const PersonaScaffold({
    super.key,
    required this.role,
    required this.title,
    required this.subtitle,
    required this.children,
    this.floatingActionButton,
  });

  final UserRole role;
  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Ação fixa do painel, sempre visível independente do scroll (ex.: "Gerar
  /// briefing executivo" no painel do CISO).
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppUser? user = ref.watch(appUserProvider).value;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(theme.brightness),
      child: Scaffold(
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    const ElytronLogo(size: 32, showGlow: false),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Olá, ${user?.firstName ?? 'executivo'}',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            role.shortLabel.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: role.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Alternar tema',
                      onPressed: () =>
                          ref.read(themeModeProvider.notifier).toggle(),
                      icon: Icon(
                        theme.brightness == Brightness.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: scheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: () => unawaited(
                        ref.read(signInControllerProvider.notifier).signOut(),
                      ),
                      icon: Icon(
                        Icons.logout,
                        color: scheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: scheme.outlineVariant, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    Text(title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.xl),
                    ...children,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
