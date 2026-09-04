import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/surface_card.dart';

/// Atalho das contas de demonstração na `SignInScreen`. Só aparece em modo
/// mock. Isolado para manter aquele arquivo abaixo do limite de 250 linhas.
class SignInDemoAccountsCard extends StatelessWidget {
  const SignInDemoAccountsCard({super.key, required this.onSelect});

  final void Function(String email) onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SurfaceCard(
      accent: scheme.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.science_outlined, size: 20, color: scheme.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Modo de demonstração',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sem Firebase configurado. Toque em uma conta para preencher.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final String email in AppConfig.demoAccounts.keys)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: InkWell(
                onTap: () => onSelect(email),
                borderRadius: AppRadius.fieldRadius,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.fieldRadius,
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
