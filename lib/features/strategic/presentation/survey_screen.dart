import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/chart_tokens.dart';
import '../data/strategic_providers.dart';
import '../domain/survey.dart';

/// Pesquisa da persona estratégica: uma pergunta por vez, com barra de
/// progresso, e ao final o resultado agregado contra os pares - a
/// recompensa por responder é justamente ver onde o CISO está em relação a
/// eles.
///
/// Se [Survey.alreadyResponded] já é verdadeiro ao abrir (o usuário voltou à
/// pesquisa depois de já ter respondido), pula direto para o resultado.
class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key, required this.survey});

  final Survey survey;

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  int _questionIndex = 0;
  late final Map<String, String> _answers = widget.survey.yourAnswers == null
      ? <String, String>{}
      : Map<String, String>.of(widget.survey.yourAnswers!);
  late bool _showResults = widget.survey.alreadyResponded;
  bool _submitting = false;
  String? _submitError;

  Survey get _survey => widget.survey;

  void _selectAnswer(String questionId, String option) {
    setState(() => _answers[questionId] = option);
  }

  void _goBack() {
    if (_questionIndex == 0) {
      return;
    }
    setState(() => _questionIndex -= 1);
  }

  Future<void> _goNextOrFinish() async {
    if (_questionIndex < _survey.questions.length - 1) {
      setState(() => _questionIndex += 1);
      return;
    }

    final String? tenantId = ref.read(appUserProvider).value?.tenantId;
    final String? uid = ref.read(appUserProvider).value?.uid;
    if (tenantId == null || uid == null) {
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await ref.read(strategicRepositoryProvider).submitSurveyResponse(
            tenantId: tenantId,
            surveyId: _survey.id,
            uid: uid,
            answers: _answers,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _showResults = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = 'Não foi possível registrar sua resposta agora. '
            'Tente novamente.';
      });
    }
  }

  void _close() {
    ref.invalidate(surveyProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showResults ? 'Como você se compara' : _survey.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Fechar',
          onPressed: _close,
        ),
      ),
      body: SafeArea(
        child: _showResults
            ? _SurveyResults(
                survey: _survey, answers: _answers, onClose: _close)
            : _SurveyQuestionStep(
                survey: _survey,
                questionIndex: _questionIndex,
                answers: _answers,
                submitting: _submitting,
                submitError: _submitError,
                onSelectAnswer: _selectAnswer,
                onBack: _goBack,
                onNextOrFinish: _goNextOrFinish,
              ),
      ),
    );
  }
}

class _SurveyQuestionStep extends StatelessWidget {
  const _SurveyQuestionStep({
    required this.survey,
    required this.questionIndex,
    required this.answers,
    required this.submitting,
    required this.submitError,
    required this.onSelectAnswer,
    required this.onBack,
    required this.onNextOrFinish,
  });

  final Survey survey;
  final int questionIndex;
  final Map<String, String> answers;
  final bool submitting;
  final String? submitError;
  final void Function(String questionId, String option) onSelectAnswer;
  final VoidCallback onBack;
  final Future<void> Function() onNextOrFinish;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final SurveyQuestion question = survey.questions[questionIndex];
    final String? selected = answers[question.id];
    final bool isLast = questionIndex == survey.questions.length - 1;
    final double progress = (questionIndex + 1) / survey.questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Semantics(
            label:
                'Pergunta ${questionIndex + 1} de ${survey.questions.length}.',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: scheme.outlineVariant,
                color: scheme.primary,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Text(
                'Pergunta ${questionIndex + 1} de ${survey.questions.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                question.prompt,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              RadioGroup<String>(
                groupValue: selected,
                onChanged: (String? value) {
                  if (value != null) {
                    onSelectAnswer(question.id, value);
                  }
                },
                child: Column(
                  children: <Widget>[
                    for (final String option in question.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Semantics(
                          button: true,
                          selected: selected == option,
                          child: RadioListTile<String>(
                            value: option,
                            title: Text(option),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: scheme.outline.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (submitError != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  submitError!,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: <Widget>[
                if (questionIndex > 0) ...<Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: submitting ? null : onBack,
                      child: const Text('Voltar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: (selected == null || submitting)
                        ? null
                        : () => onNextOrFinish(),
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLast ? 'Concluir' : 'Próxima'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SurveyResults extends StatelessWidget {
  const _SurveyResults({
    required this.survey,
    required this.answers,
    required this.onClose,
  });

  final Survey survey;
  final Map<String, String> answers;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  'Obrigado! Veja como sua resposta se compara à de outros '
                  'CISOs do seu setor.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${survey.respondentCount} CISOs já responderam esta pesquisa.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (final SurveyQuestion question in survey.questions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: _QuestionResult(
                    question: question,
                    yourAnswer: answers[question.id],
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FilledButton(
              onPressed: onClose,
              child: const Text('Voltar ao feed'),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionResult extends StatelessWidget {
  const _QuestionResult({required this.question, required this.yourAnswer});

  final SurveyQuestion question;
  final String? yourAnswer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          question.prompt,
          style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OptionShareBar(
              option: question.options[i],
              percent: question.peerDistribution[i],
              isYourAnswer: question.options[i] == yourAnswer,
            ),
          ),
      ],
    );
  }
}

class _OptionShareBar extends StatelessWidget {
  const _OptionShareBar({
    required this.option,
    required this.percent,
    required this.isYourAnswer,
  });

  final String option;
  final int percent;
  final bool isYourAnswer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color barColor = isYourAnswer
        ? ChartTokens.categoricalSlot1
        : scheme.onSurfaceVariant.withValues(alpha: 0.4);
    final int clampedPercent = percent.clamp(0, 100);

    return Semantics(
      label: '$option: $percent por cento dos CISOs'
          '${isYourAnswer ? ', esta foi a sua resposta' : ''}.',
      container: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (isYourAnswer) ...<Widget>[
                Icon(Icons.check_circle_rounded, size: 16, color: barColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  option,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight:
                        isYourAnswer ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (isYourAnswer) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Sua resposta',
              style: theme.textTheme.labelSmall?.copyWith(color: barColor),
            ),
          ],
          const SizedBox(height: AppSpacing.xxs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: clampedPercent,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: barColor),
                    ),
                  ),
                  Expanded(
                    flex: 100 - clampedPercent,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
