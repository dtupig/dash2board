import '../../domain/survey.dart';

/// Quantos CISOs de outros tenants já responderam, antes de qualquer
/// resposta desta sessão - a prova social que o convite mostra de saída.
const int baseRespondentCount = 214;

const String activeSurveyId = 'seguranca-2027-prioridades';

List<SurveyQuestion> buildSurveyQuestions() => const <SurveyQuestion>[
      SurveyQuestion(
        id: 'maior-obstaculo',
        prompt:
            'Qual é o maior obstáculo para reduzir as lacunas de compliance '
            'na sua empresa hoje?',
        options: <String>[
          'Orçamento insuficiente',
          'Falta de pessoal especializado',
          'Prioridade concorrente com outras áreas de TI',
          'Dificuldade em obter evidência dos donos de cada controle',
        ],
        peerDistribution: <int>[34, 29, 21, 16],
      ),
      SurveyQuestion(
        id: 'prazo-reducao',
        prompt: 'Em quanto tempo você espera reduzir pela metade o número de '
            'lacunas abertas?',
        options: <String>[
          'Até 3 meses',
          'De 3 a 6 meses',
          'De 6 a 12 meses',
          'Mais de 12 meses',
        ],
        peerDistribution: <int>[9, 31, 42, 18],
      ),
      SurveyQuestion(
        id: 'domínio-investido',
        prompt: 'Qual domínio de segurança recebeu mais investimento da sua '
            'empresa no último ano?',
        options: <String>[
          'Identidade e Acesso',
          'Nuvem',
          'Segurança de Aplicações',
          'Terceiros',
        ],
        peerDistribution: <int>[38, 27, 24, 11],
      ),
    ];
