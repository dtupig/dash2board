import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/surface_card.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/persona_visuals.dart';
import '../../shell/persona_scaffold.dart';
import '../../strategic/presentation/widgets/data_freshness_footer.dart';
import '../../strategic/presentation/widgets/domain_risk_section.dart';
import '../../strategic/presentation/widgets/posture_headline.dart';
import '../../strategic/presentation/widgets/posture_trend_section.dart';
import '../../strategic/presentation/widgets/top_risks_section.dart';

/// Largura a partir da qual os blocos 3 e 4 (risco por domínio e top riscos)
/// passam a dividir a largura em duas colunas, em vez de empilhar.
const double _twoColumnBreakpoint = 600;

/// Persona 2 - segurança estratégica e CISO.
///
/// Painel v1 (prompt 4): ao rolar até o fim, o CISO consegue dizer três
/// frases - "nossa postura está em X, subiu/caiu Y no ano", "o problema está
/// concentrado em `domínio`" e "comparado ao setor, estamos acima/abaixo".
/// Cada bloco é um widget próprio em `strategic/presentation/widgets/`, que
/// resolve seu próprio carregamento/vazio/erro - esta tela só compõe.
class StrategicDashboardScreen extends StatelessWidget {
  const StrategicDashboardScreen({super.key});

  void _viewInsights(BuildContext context) {
    // Caminho literal em vez de importar `app/router.dart` (evita import
    // circular entre o roteador e as telas que ele registra). Mantenha em
    // sincronia com `AppRoute.strategicInsights`.
    context.go('/estrategia/insights');
  }

  void _viewBriefing(BuildContext context) {
    // Mesmo motivo do caminho literal acima - mantenha em sincronia com
    // `AppRoute.strategicBriefing`.
    context.go('/estrategia/briefing');
  }

  @override
  Widget build(BuildContext context) {
    const UserRole role = UserRole.strategic;

    return PersonaScaffold(
      role: role,
      title: 'Postura & Estratégia',
      subtitle:
          'Como a organização evoluiu, onde está o risco concentrado e qual '
          'evidência sustenta a próxima decisão.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _viewBriefing(context),
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Gerar briefing'),
      ),
      children: <Widget>[
        // Bloco 1 - hero number.
        const PostureHeadline(),
        const SizedBox(height: AppSpacing.xl),

        // Bloco 2 - tendência de 12 meses.
        const PostureTrendSection(),
        const SizedBox(height: AppSpacing.xl),

        // Blocos 3 e 4 - risco por domínio e top riscos de negócio, lado a
        // lado a partir de 600 de largura.
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth >= _twoColumnBreakpoint) {
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: DomainRiskSection()),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(child: TopRisksSection()),
                ],
              );
            }
            return const Column(
              children: <Widget>[
                DomainRiskSection(),
                SizedBox(height: AppSpacing.xl),
                TopRisksSection(),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),

        // Atalho para o feed de insights e pesquisas (prompt 6) - não faz
        // parte dos 5 blocos do prompt 4, mas já existia aqui e continua
        // valendo como ponto de entrada do painel.
        SurfaceCard(
          accent: role.accent,
          onTap: () => _viewInsights(context),
          semanticLabel:
              'Insights e pesquisas Elytron. Tendências curadas, benchmarks '
              'e pesquisas respondidas por CISOs do mesmo segmento. Toque '
              'para abrir.',
          child: ExcludeSemantics(
            child: Row(
              children: <Widget>[
                Icon(Icons.auto_graph_outlined, color: role.accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Insights e pesquisas Elytron',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Tendências curadas, benchmarks e pesquisas '
                        'respondidas por CISOs do mesmo segmento.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // Bloco 5 - rodapé de contexto.
        const DataFreshnessFooter(),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}
