import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'sign_in_form_card.dart';
import 'welcome_persona_showcase.dart';

/// Composição de duas colunas de `WelcomeScreen` em `large` (HU-W-06): marca
/// + headline + vitrine de personas à esquerda, formulário de login já
/// embutido à direita - sem navegação separada para `/entrar`, como no
/// mockup web da Fase 1 (`Dash2Board Web.dc.html`). Isolado para manter
/// `welcome_screen.dart` abaixo do limite de 250 linhas.
///
/// [brand]/[headline] chegam prontos de `welcome_screen.dart`, que é onde
/// as classes privadas que os constroem (`_Brand`/`_Headline`, reusadas
/// também no layout de tela estreita) vivem.
class WelcomeWideLayout extends StatelessWidget {
  const WelcomeWideLayout({
    super.key,
    required this.brand,
    required this.headline,
  });

  final Widget brand;
  final Widget headline;

  static const double _maxWidth = 1280;
  static const double _loginColumnWidth = 420;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                brand,
                const SizedBox(height: AppSpacing.xxxl),
                headline,
                const SizedBox(height: AppSpacing.xl),
                const PersonaShowcase(),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xxxl),
          SizedBox(
            width: _loginColumnWidth,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.4),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: const SignInFormCard(showLogo: false),
            ),
          ),
        ],
      ),
    );
  }
}
