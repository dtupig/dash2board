import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/chart_tokens.dart';
import '../../../core/widgets/charts/severity_chip.dart';
import '../domain/insight_item.dart';
import 'insight_topic_tag.dart';
import 'insights_formatting.dart';

/// Detalhe em tela cheia de um [InsightItem]: o texto completo (o próprio
/// [InsightItem.summary] já é a informação, não um teaser - regra editorial
/// do feed) e o caminho até a fonte original.
class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});

  final InsightItem insight;

  Future<void> _copySourceLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: insight.sourceUrl));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link da fonte copiado.')),
    );
    // TODO: abrir a fonte direto no navegador (url_launcher) fica para um
    // próximo prompt. Por ora, copiamos o link para a área de transferência.
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Insight')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                TopicTag(topic: insight.topic),
                if (insight.isBenchmark)
                  const SeverityChip.custom(
                    icon: Icons.groups_2_outlined,
                    color: ChartTokens.categoricalSlot2,
                    label: 'Benchmark de setor',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text(
                insight.title,
                style: textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${insight.sourceName} · ${formatShortDatePtBr(insight.publishedAt)}',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              insight.summary,
              style: textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.xl),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.xxxl),
              child: OutlinedButton.icon(
                onPressed: () => _copySourceLink(context),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Abrir fonte'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              insight.sourceUrl,
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
