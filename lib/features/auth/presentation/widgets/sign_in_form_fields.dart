import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Campos de e-mail e senha (+ link "esqueci minha senha") da
/// `SignInScreen`. Isolado para manter aquele arquivo abaixo do limite de
/// 250 linhas.
class SignInFormFields extends StatelessWidget {
  const SignInFormFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscurePassword,
    required this.isBusy,
    required this.onPasswordSubmitted,
    required this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscurePassword;
  final bool isBusy;
  final VoidCallback onPasswordSubmitted;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: emailController,
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
          controller: passwordController,
          label: 'Senha',
          prefixIcon: Icons.lock_outline,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.password],
          validator: Validators.passwordPresence,
          enabled: !isBusy,
          onFieldSubmitted: (_) {
            if (!isBusy) {
              onPasswordSubmitted();
            }
          },
          suffixIcon: IconButton(
            tooltip: obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
            onPressed: onToggleObscurePassword,
            icon: Icon(
              obscurePassword
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
            onPressed: isBusy ? null : onForgotPassword,
            child: const Text('Esqueci minha senha'),
          ),
        ),
      ],
    );
  }
}
