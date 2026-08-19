import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/survey.dart';

/// Convite para responder a pesquisa ativa, no topo do feed de insights.
///
/// Depois de respondida, vira um convite para revisitar o resultado - a
/// pesquisa nunca desaparece, porque ver a comparação de novo também tem
/// valor.
class SurveyInviteCard extends StatelessWidget {
  const SurveyInviteCard(
      {super.key, required this.survey, required this.onTap});

  final Survey survey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool responded = survey.alreadyResponded;

    return SurfaceCard(
      onTap: onTap,
      accent: scheme.primary,
      semanticLabel: responded
          ? '${survey.title}. Você já respondeu. Toque para ver como você '
              'se compara aos pares.'
          : '${survey.title}. ${survey.respondentCount} CISOs já '
              'responderam. Toque para responder.',
      child: Row(
        children: <Widget>[
          Icon(
            responded ? Icons.leaderboard_rounded : Icons.poll_outlined,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    survey.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    responded
                        ? 'Você já respondeu · toque para ver a comparação'
                        : '${survey.respondentCount} CISOs já responderam',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
