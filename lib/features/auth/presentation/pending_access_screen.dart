import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aurora_backdrop.dart';
import '../../../core/widgets/elytron_logo.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/app_user.dart';
import '../domain/user_role.dart';
import 'persona_visuals.dart';
import 'sign_in_controller.dart';

/// Usuário autenticado, porém ainda sem papel/tenant provisionado.
///
/// É um estado legítimo e esperado em produto B2B: a conta existe no
/// Firebase Auth antes do administrador do cliente atribuir a persona.
class PendingAccessScreen extends ConsumerWidget {
  const PendingAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppUser? user = ref.watch(appUserProvider).value;
    final AsyncValue<void> action = ref.watch(signInControllerProvider);
    final bool isBusy = action.isLoading;
    final Object? error = action.hasError ? action.error : null;
    final AppFailure? failure = error is AppFailure
        ? error
        : (error == null ? null : const AppFailure.unknown());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(theme.brightness),
      child: Scaffold(
        body: AuroraBackdrop(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Center(child: ElytronLogo(size: 64)),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Quase lá, ${user?.firstName ?? 'executivo'}.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        UserRole.pending.valueProposition,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SurfaceCard(
                        accent: UserRole.pending.accent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(
                                  UserRole.pending.icon,
                                  size: 20,
                                  color: UserRole.pending.accent,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    user?.email ?? 'Conta autenticada',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            for (final String item
                                in UserRole.pending.highlights)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (failure != null) ...<Widget>[
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer.withValues(alpha: 0.28),
                              borderRadius: AppRadius.fieldRadius,
                              border: Border.all(
                                color: scheme.error.withValues(alpha: 0.55),
                              ),
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
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      FilledButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => unawaited(
                                  ref
                                      .read(signInControllerProvider.notifier)
                                      .refreshClaims(),
                                ),
                        icon: isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh, size: 20),
                        label: Text(
                          isBusy ? 'Verificando...' : 'Verificar liberação agora',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => unawaited(
                                  ref
                                      .read(signInControllerProvider.notifier)
                                      .signOut(),
                                ),
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text('Sair'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Precisa de ajuda? ${AppConfig.supportEmail}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
