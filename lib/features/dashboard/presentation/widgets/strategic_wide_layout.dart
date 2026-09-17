import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../strategic/presentation/widgets/domain_risk_section.dart';
import '../../../strategic/presentation/widgets/posture_headline.dart';
import '../../../strategic/presentation/widgets/posture_trend_section.dart';
import '../../../strategic/presentation/widgets/top_risks_section.dart';

/// Composição de `large` do painel estratégico (HU-W-10): índice de
/// postura, tendência de 12 meses e risco por domínio lado a lado, sem
/// rolagem - as 3 frases que o CISO precisa dizer, todas visíveis de uma
/// vez, como no mockup web da Fase 1. `TopRisksSection` vem embaixo, largura
/// cheia - não tem par direto no mockup, mas o conteúdo é real (nenhum bloco
/// aqui é inventado, todos já existem no painel estreito de hoje).
///
/// Reaproveita os mesmos widgets do layout empilhado (`PostureHeadline` etc.
/// já resolvem seu próprio carregamento/vazio/erro) - isolado só para manter
/// `strategic_dashboard_screen.dart` abaixo do limite de 250 linhas.
class StrategicWideLayout extends StatelessWidget {
  const StrategicWideLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(flex: 9, child: PostureHeadline()),
              SizedBox(width: AppSpacing.lg),
              Expanded(flex: 14, child: PostureTrendSection()),
              SizedBox(width: AppSpacing.lg),
              Expanded(flex: 10, child: DomainRiskSection()),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        TopRisksSection(),
      ],
    );
  }
}
