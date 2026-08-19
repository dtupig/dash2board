import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/aurora_backdrop.dart';
import '../../../core/widgets/elytron_logo.dart';
import '../../../core/widgets/surface_card.dart';
import 'sign_in_controller.dart';

/// Autenticação por e-mail corporativo e senha.
///
/// Em caso de sucesso NÃO navegamos manualmente: o `redirect` do GoRouter
/// observa o estado do usuário e leva à rota da persona correspondente.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(signInControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  Future<void> _forgotPassword() async {
    final String? email = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => _ResetPasswordDialog(
        initialEmail: _emailController.text,
      ),
    );

    if (email == null || email.isEmpty) {
      return;
    }

    await ref.read(signInControllerProvider.notifier).sendPasswordReset(email);

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Se este e-mail estiver cadastrado, você receberá as instruções em '
          'instantes.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AsyncValue<void> signInState = ref.watch(signInControllerProvider);
    final bool isBusy = signInState.isLoading;

    final Object? error = signInState.hasError ? signInState.error : null;
    final AppFailure? failure = error is AppFailure ? error : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(theme.brightness),
      child: Scaffold(
        body: AuroraBackdrop(
          child: SafeArea(
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: IconButton(
                      onPressed: isBusy
                          ? null
                          : () => context.go(AppRoute.welcome),
                      tooltip: 'Voltar',
                      icon: Icon(
                        Icons.arrow_back,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSpacing.maxContentWidth,
                        ),
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const Center(child: ElytronLogo(size: 56)),
                                const SizedBox(height: AppSpacing.xl),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'Entrar',
                                    style: theme.textTheme.displaySmall,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Use o e-mail corporativo cadastrado pela '
                                  'sua organização.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                if (failure != null) ...<Widget>[
                                  _ErrorBanner(failure: failure),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                AppTextField(
                                  controller: _emailController,
                                  label: 'E-mail corporativo',
                                  hint: 'nome@suaempresa.com',
                                  prefixIcon: Icons.alternate_email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const <String>[
                                    AutofillHints.username,
                                    AutofillHints.email,
                                  ],
                                  validator: Validators.email,
                                  enabled: !isBusy,
                                  autofocus: true,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppTextField(
                                  controller: _passwordController,
                                  label: 'Senha',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const <String>[
                                    AutofillHints.password,
                                  ],
                                  validator: Validators.passwordPresence,
                                  enabled: !isBusy,
                                  onFieldSubmitted: (_) {
                                    if (!isBusy) {
                                      unawaited(_submit());
                                    }
                                  },
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Mostrar senha'
                                        : 'Ocultar senha',
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed:
                                        isBusy ? null : () => unawaited(
                                              _forgotPassword(),
                                            ),
                                    child: const Text('Esqueci minha senha'),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                FilledButton(
                                  onPressed:
                                      isBusy ? null : () => unawaited(_submit()),
                                  child: isBusy
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        )
                                      : const Text('Entrar'),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _SecurityNotice(scheme: scheme),
                                if (AppConfig.useMockData) ...<Widget>[
                                  const SizedBox(height: AppSpacing.md),
                                  _DemoAccountsCard(
                                    onSelect: (String email) {
                                      setState(() {
                                        _emailController.text = email;
                                        _passwordController.text =
                                            'demo-elytron-2026';
                                      });
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.failure});

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

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice({required this.scheme});

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

/// Atalho das contas de demonstração. Só aparece em modo mock.
class _DemoAccountsCard extends StatelessWidget {
  const _DemoAccountsCard({required this.onSelect});

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

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialEmail);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      title: const Text('Redefinir senha'),
      content: Form(
        key: _formKey,
        child: AppTextField(
          controller: _controller,
          label: 'E-mail corporativo',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: Validators.email,
          onFieldSubmitted: (_) => _confirm(),
          autofocus: true,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
