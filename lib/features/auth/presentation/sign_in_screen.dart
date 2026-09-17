import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aurora_backdrop.dart';
import 'widgets/sign_in_form_card.dart';

/// Autenticação por e-mail corporativo e senha - `/entrar`.
///
/// Em caso de sucesso NÃO navegamos manualmente: o `redirect` do GoRouter
/// observa o estado do usuário e leva à rota da persona correspondente.
///
/// O formulário em si (campos, banner de erro, contas de demonstração,
/// diálogo de redefinição de senha) vive em
/// `widgets/sign_in_form_card.dart` - reaproveitado também dentro de
/// `WelcomeScreen` em `large` (HU-W-06), onde o login aparece direto na
/// boas-vindas em vez de exigir uma navegação separada.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

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
                      onPressed: () => context.go(AppRoute.welcome),
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
                        child: const SignInFormCard(),
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
