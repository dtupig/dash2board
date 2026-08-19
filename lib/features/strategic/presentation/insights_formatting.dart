const List<String> _fullMonthsPtBr = <String>[
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// Cabeçalho de agrupamento mensal do feed (ex.: "Julho de 2026").
///
/// Manual, sem `intl`/`DateFormat`, pelo mesmo motivo de
/// `compliance_formatting.dart`: sem depender de locale carregado em tempo
/// de execução, e determinístico em teste de widget.
String formatMonthYearPtBr(DateTime date) {
  final String month = _fullMonthsPtBr[date.month - 1];
  return '${month[0].toUpperCase()}${month.substring(1)} de ${date.year}';
}

const List<String> _shortMonthsPtBr = <String>[
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

/// Data curta em pt-BR (ex.: "27 jul 2026"), usada no card e no detalhe do
/// insight.
String formatShortDatePtBr(DateTime date) {
  return '${date.day} ${_shortMonthsPtBr[date.month - 1]} ${date.year}';
}

/// Chave de agrupamento por mês (ano*12+mês), estável para comparação.
int monthGroupKey(DateTime date) => date.year * 12 + date.month;
