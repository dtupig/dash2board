/// Formatação de datas compartilhada por `trend_line_chart.dart`,
/// `trend_line_chart_tooltip.dart` e `trend_line_chart_painter.dart` -
/// isolada para não duplicar a lista de meses entre os três.
const List<String> monthAbbreviations = <String>[
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

String formatMonth(DateTime date) {
  final String year2 = (date.year % 100).toString().padLeft(2, '0');
  return '${monthAbbreviations[date.month - 1]}/$year2';
}
