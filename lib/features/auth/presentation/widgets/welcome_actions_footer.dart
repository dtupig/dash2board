import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_spacing.dart';

/// CTAs de entrada da `WelcomeScreen`. Isolado para manter aquele arquivo
/// abaixo do limite de 250 linhas.
class WelcomeActions extends StatelessWidget {
  const WelcomeActions({super.key});

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

/// Rodapé legal da `WelcomeScreen`. Ver [WelcomeActions].
class WelcomeFooter extends StatelessWidget {
  const WelcomeFooter({super.key, required this.scheme});

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
