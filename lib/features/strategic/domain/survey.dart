/// Uma pergunta de múltipla escolha (resposta única) de uma [Survey].
///
/// [peerDistribution] é o percentual de respondentes que escolheu cada opção
/// de [options] (mesmo índice) — um agregado pré-calculado, nunca somado no
/// cliente (`docs/01_MODELO_DADOS_FIRESTORE.md`: "agregados são
/// pré-calculados por Cloud Functions para que cada card custe uma leitura").
class SurveyQuestion {
  const SurveyQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.peerDistribution,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final List<int> peerDistribution;

  factory SurveyQuestion.fromMap(Map<String, Object?> map) {
    return SurveyQuestion(
      id: map['id'] as String? ?? '',
      prompt: map['prompt'] as String? ?? '',
      options: <String>[
        for (final Object? option
            in (map['options'] as List?) ?? const <Object?>[])
          option as String,
      ],
      peerDistribution: <int>[
        for (final Object? share
            in (map['peerDistribution'] as List?) ?? const <Object?>[])
          (share as num).toInt(),
      ],
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'prompt': prompt,
        'options': options,
        'peerDistribution': peerDistribution,
      };

  @override
  bool operator ==(Object other) {
    if (other is! SurveyQuestion) {
      return false;
    }
    if (other.id != id || other.prompt != prompt) {
      return false;
    }
    if (other.options.length != options.length ||
        other.peerDistribution.length != peerDistribution.length) {
      return false;
    }
    for (int i = 0; i < options.length; i++) {
      if (other.options[i] != options[i]) {
        return false;
      }
    }
    for (int i = 0; i < peerDistribution.length; i++) {
      if (other.peerDistribution[i] != peerDistribution[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        prompt,
        Object.hashAll(options),
        Object.hashAll(peerDistribution),
      );

  @override
  String toString() => 'SurveyQuestion($id, ${options.length} opções)';
}

/// Pesquisa curada pela Elytron para a persona estratégica (CISO).
///
/// Espelha `surveys/{id}` (`docs/01_MODELO_DADOS_FIRESTORE.md`). As
/// respostas individuais ficam em `responses/{uid}`, isoladas por usuário;
/// [yourAnswers] é a resposta do usuário atual, se já existir, usada para
/// abrir o resultado agregado direto ao revisitar a pesquisa.
class Survey {
  const Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.respondentCount,
    this.yourAnswers,
  });

  final String id;
  final String title;
  final String description;
  final List<SurveyQuestion> questions;

  /// Quantos CISOs já responderam — é a prova social que convida a
  /// responder ("X CISOs já responderam").
  final int respondentCount;

  /// Respostas do usuário atual (`questionId` -> opção escolhida), ou `null`
  /// se ele ainda não respondeu esta pesquisa.
  final Map<String, String>? yourAnswers;

  bool get alreadyResponded => yourAnswers != null;

  factory Survey.fromMap(
    Map<String, Object?> map, {
    Map<String, String>? yourAnswers,
  }) {
    return Survey(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      questions: <SurveyQuestion>[
        for (final Object? question
            in (map['questions'] as List?) ?? const <Object?>[])
          SurveyQuestion.fromMap((question as Map).cast<String, Object?>()),
      ],
      respondentCount: (map['respondentCount'] as num?)?.toInt() ?? 0,
      yourAnswers: yourAnswers,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'description': description,
        'questions': <Map<String, Object?>>[
          for (final SurveyQuestion question in questions) question.toMap(),
        ],
        'respondentCount': respondentCount,
      };

  Survey copyWith({
    String? id,
    String? title,
    String? description,
    List<SurveyQuestion>? questions,
    int? respondentCount,
    Map<String, String>? yourAnswers,
  }) {
    return Survey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      respondentCount: respondentCount ?? this.respondentCount,
      yourAnswers: yourAnswers ?? this.yourAnswers,
    );
  }

  @override
  String toString() =>
      'Survey($id, ${questions.length} perguntas, $respondentCount respostas)';
}
