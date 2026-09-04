import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/surface_card.dart';

/// Banner de erro de autenticação da `SignInScreen`. Isolado para manter
/// aquele arquivo abaixo do limite de 250 linhas.
class SignInErrorBanner extends StatelessWidget {
  const SignInErrorBanner({super.key, required this.failure});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.28),
          borderRadius: AppRadius.fieldRadius,
          border: Border.all(color: scheme.error.withValues(alpha: 0.55)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.error_outline, size: 20, color: scheme.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                failure.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso de segurança abaixo do formulário. Ver [SignInErrorBanner].
class SignInSecurityNotice extends StatelessWidget {
  const SignInSecurityNotice({super.key, required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.privacy_tip_outlined,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Sessão protegida', style: text.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tentativas de acesso são registradas em trilha de auditoria. '
                  'Dúvidas: ${AppConfig.supportEmail}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
