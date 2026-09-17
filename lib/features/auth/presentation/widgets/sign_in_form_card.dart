import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/elytron_logo.dart';
import '../sign_in_controller.dart';
import 'reset_password_dialog.dart';
import 'sign_in_banner_notice.dart';
import 'sign_in_demo_accounts_card.dart';
import 'sign_in_form_fields.dart';

/// O formulário de login em si - e-mail, senha, aviso de erro/segurança e
/// contas de demonstração -, sem a casca de tela (`Scaffold`, fundo,
/// botão de voltar). Extraído de `SignInScreen` para ser reaproveitado ali
/// **e** embutido na coluna direita de `WelcomeScreen` em `large`
/// (HU-W-06: o mockup web da Fase 1 mostra o login já na própria
/// boas-vindas, não como navegação separada, a partir de `>=1200px`).
///
/// [showLogo] existe porque o card embutido em `WelcomeScreen` já está ao
/// lado da marca (mostrada uma vez no bloco à esquerda) - repetir o logo
/// dentro do card de login seria redundante só nesse caso.
class SignInFormCard extends ConsumerStatefulWidget {
  const SignInFormCard({super.key, this.showLogo = true});

  final bool showLogo;

  @override
  ConsumerState<SignInFormCard> createState() => _SignInFormCardState();
}

class _SignInFormCardState extends ConsumerState<SignInFormCard> {
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
      builder: (BuildContext dialogContext) => ResetPasswordDialog(
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

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.showLogo) ...<Widget>[
              const Center(child: ElytronLogo(size: 56)),
              const SizedBox(height: AppSpacing.xl),
            ],
            Semantics(
              header: true,
              child: Text('Entrar', style: theme.textTheme.displaySmall),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Use o e-mail corporativo cadastrado pela sua organização.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (failure != null) ...<Widget>[
              SignInErrorBanner(failure: failure),
              const SizedBox(height: AppSpacing.lg),
            ],
            SignInFormFields(
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              onToggleObscurePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              isBusy: isBusy,
              onPasswordSubmitted: () => unawaited(_submit()),
              onForgotPassword: () => unawaited(_forgotPassword()),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: isBusy ? null : () => unawaited(_submit()),
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
            SignInSecurityNotice(scheme: scheme),
            if (AppConfig.useMockData) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              SignInDemoAccountsCard(
                onSelect: (String email) {
                  setState(() {
                    _emailController.text = email;
                    _passwordController.text = 'demo-elytron-2026';
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
