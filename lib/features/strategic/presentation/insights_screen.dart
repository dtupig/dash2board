import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/chart_tokens.dart';
import '../../../core/widgets/charts/chart_frame.dart';
import '../../../core/widgets/charts/severity_chip.dart';
import '../../../core/widgets/surface_card.dart';
import '../data/strategic_providers.dart';
import '../domain/insight_item.dart';
import '../domain/survey.dart';
import 'insight_detail_screen.dart';
import 'insight_topic_tag.dart';
import 'insights_formatting.dart';
import 'survey_invite_card.dart';
import 'survey_screen.dart';

/// Feed de insights, tendências e benchmarks curados pela Elytron para o
/// CISO - `/estrategia/insights`.
///
/// Regra editorial: o resumo de cada item tem que dizer o fato, não
/// prometer o fato ("leia mais" genérico é proibido).
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String? _selectedTopic;

  void _openDetail(InsightItem insight) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            InsightDetailScreen(insight: insight),
      ),
    );
  }

  void _openSurvey(Survey survey) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SurveyScreen(survey: survey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<InsightItem>> insightsAsync =
        ref.watch(insightsProvider);
    final AsyncValue<Survey?> surveyAsync = ref.watch(surveyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights e pesquisas')),
      body: SafeArea(
        child: insightsAsync.when(
          loading: () => const _InsightsLoadingBody(),
          error: (Object error, StackTrace stackTrace) => _InsightsErrorBody(
            onRetry: () => ref.invalidate(insightsProvider),
          ),
          data: (List<InsightItem> insights) => _InsightsBody(
            insights: insights,
            survey: surveyAsync.value,
            selectedTopic: _selectedTopic,
            onSelectTopic: (String? topic) =>
                setState(() => _selectedTopic = topic),
            onOpenDetail: _openDetail,
            onOpenSurvey: _openSurvey,
          ),
        ),
      ),
    );
  }
}

class _InsightsLoadingBody extends StatelessWidget {
  const _InsightsLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: ChartFrame(title: 'Insights', height: 320, child: ChartLoading()),
    );
  }
}

class _InsightsErrorBody extends StatelessWidget {
  const _InsightsErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ChartFrame(
        title: 'Insights',
        height: 240,
        child: ChartError(
          message: 'Não foi possível carregar os insights agora.',
          onRetry: onRetry,
        ),
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({
    required this.insights,
    required this.survey,
    required this.selectedTopic,
    required this.onSelectTopic,
    required this.onOpenDetail,
    required this.onOpenSurvey,
  });

  final List<InsightItem> insights;
  final Survey? survey;
  final String? selectedTopic;
  final ValueChanged<String?> onSelectTopic;
  final ValueChanged<InsightItem> onOpenDetail;
  final ValueChanged<Survey> onOpenSurvey;

  List<String> _topics() {
    final List<String> topics = insights
        .map((InsightItem i) => i.topic)
        .toSet()
        .toList(growable: false);
    topics.sort();
    return topics;
  }

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ChartFrame(
          title: 'Insights',
          height: 200,
          child: ChartEmpty(
            message: 'Ainda não há insights publicados para o seu tenant.',
          ),
        ),
      );
    }

    final List<InsightItem> filtered = selectedTopic == null
        ? insights
        : insights.where((InsightItem i) => i.topic == selectedTopic).toList(
              growable: false,
            );
    // Achatado em linhas (cabeçalho de mês ou insight) para que o feed - que
    // só cresce ao longo da vida do produto - seja construído sob demanda
    // pelo `SliverList.builder`, não tudo de uma vez como uma lista comum.
    final List<_FeedRow> rows = _flattenByMonth(filtered);

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverList.list(
            children: <Widget>[
              if (survey != null) ...<Widget>[
                SurveyInviteCard(
                  survey: survey!,
                  onTap: () => onOpenSurvey(survey!),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              _TopicFilterRow(
                topics: _topics(),
                selectedTopic: selectedTopic,
                onSelectTopic: onSelectTopic,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: ChartEmpty(
                    message: 'Nenhum insight no tópico "$selectedTopic".',
                    actionLabel: 'Limpar filtro',
                    onAction: () => onSelectTopic(null),
                  ),
                ),
            ],
          ),
        ),
        if (filtered.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            sliver: SliverList.builder(
              itemCount: rows.length,
              itemBuilder: (BuildContext context, int index) {
                final _FeedRow row = rows[index];
                if (row.isHeader) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSpacing.sm,
                      0,
                      AppSpacing.sm,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(
                        formatMonthYearPtBr(row.headerDate!),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _InsightCard(
                    insight: row.insight!,
                    onTap: () => onOpenDetail(row.insight!),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  List<_FeedRow> _flattenByMonth(List<InsightItem> items) {
    final List<_FeedRow> rows = <_FeedRow>[];
    int? lastKey;
    for (final InsightItem item in items) {
      final int key = monthGroupKey(item.publishedAt);
      if (key != lastKey) {
        rows.add(_FeedRow.header(item.publishedAt));
        lastKey = key;
      }
      rows.add(_FeedRow.insight(item));
    }
    return rows;
  }
}

/// Uma linha do feed achatado: ou o cabeçalho de um mês, ou um insight.
class _FeedRow {
  const _FeedRow.header(this.headerDate) : insight = null;
  const _FeedRow.insight(this.insight) : headerDate = null;

  final DateTime? headerDate;
  final InsightItem? insight;

  bool get isHeader => headerDate != null;
}

class _TopicFilterRow extends StatelessWidget {
  const _TopicFilterRow({
    required this.topics,
    required this.selectedTopic,
    required this.onSelectTopic,
  });

  final List<String> topics;
  final String? selectedTopic;
  final ValueChanged<String?> onSelectTopic;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Semantics(
              button: true,
              selected: selectedTopic == null,
              child: FilterChip(
                label: const Text('Todos'),
                selected: selectedTopic == null,
                onSelected: (_) => onSelectTopic(null),
              ),
            ),
          ),
          for (final String topic in topics)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Semantics(
                button: true,
                selected: selectedTopic == topic,
                child: FilterChip(
                  label: Text(topic),
                  selected: selectedTopic == topic,
                  onSelected: (bool isSelected) =>
                      onSelectTopic(isSelected ? topic : null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.onTap});

  final InsightItem insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SurfaceCard(
      onTap: onTap,
      semanticLabel: '${insight.title}. ${insight.summary} Fonte: '
          '${insight.sourceName}, ${formatShortDatePtBr(insight.publishedAt)}.'
          '${insight.isBenchmark ? ' Benchmark de setor.' : ''}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              insight.title,
              style:
                  theme.textTheme.titleSmall?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              insight.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${insight.sourceName} · ${formatShortDatePtBr(insight.publishedAt)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
