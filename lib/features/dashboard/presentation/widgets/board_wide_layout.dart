import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Composição de `large` do painel do board (HU-W-14): exposição financeira
/// e impacto por unidade lado a lado, como no mockup web da Fase 1 -
/// "três números, uma tendência", os dois primeiros sem precisar rolar.
/// Decisões pendentes continuam em largura cheia, mas fluem em grade
/// (`BoardPendingDecisionsSection(wide: true)`) em vez de empilhadas.
///
/// Isolado de `board_dashboard_screen.dart` para manter aquele arquivo
/// abaixo do limite de 250 linhas - todo o conteúdo real (exposição,
/// unidades, decisões) já existe e é passado pronto por quem chama.
class BoardWideLayout extends StatelessWidget {
  const BoardWideLayout({
    super.key,
    required this.exposureCard,
    required this.businessUnitSection,
    required this.pendingHeading,
    required this.pendingSection,
    required this.servicesShortcut,
  });

  final Widget exposureCard;
  final Widget businessUnitSection;
  final Widget pendingHeading;
  final Widget pendingSection;
  final Widget servicesShortcut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(flex: 10, child: exposureCard),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 12, child: businessUnitSection),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        pendingHeading,
        const SizedBox(height: AppSpacing.sm),
        pendingSection,
        const SizedBox(height: AppSpacing.xl),
        servicesShortcut,
      ],
    );
  }
}
