/// Urgência declarada de uma solicitação de serviço (RFS).
///
/// O SLA de resposta por urgência é a decisão D-30
/// (`docs/13_DECISOES_PENDENTES.md`): crise 2h, urgente 1 dia útil, planejado
/// 5 dias úteis. `nextQuarter` não tem SLA de resposta - é planejamento de
/// orçamento, não demanda ativa.
enum RequestUrgency {
  planned('planned'),
  nextQuarter('next_quarter'),
  urgent('urgent'),
  crisis('crisis');

  const RequestUrgency(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        RequestUrgency.planned => 'Planejado',
        RequestUrgency.nextQuarter => 'Próximo trimestre',
        RequestUrgency.urgent => 'Urgente',
        RequestUrgency.crisis => 'Crise',
      };

  String get slaDescription => switch (this) {
        RequestUrgency.planned => 'Resposta em até 5 dias úteis.',
        RequestUrgency.nextQuarter => 'Sem prazo de resposta - é para o '
            'planejamento do próximo trimestre.',
        RequestUrgency.urgent => 'Resposta em até 1 dia útil.',
        RequestUrgency.crisis => 'Resposta em até 2 horas.',
      };

  /// Valor desconhecido cai em [RequestUrgency.planned] - nunca assume uma
  /// urgência maior do que a que foi realmente declarada.
  static RequestUrgency fromWire(Object? value) {
    if (value is! String) {
      return RequestUrgency.planned;
    }
    for (final RequestUrgency urgency in RequestUrgency.values) {
      if (urgency.wireValue == value) {
        return urgency;
      }
    }
    return RequestUrgency.planned;
  }
}
