/// Formata uma data no padrão dd/mm/aaaa - mesma convenção duplicada em
/// `services/presentation/services_formatting.dart`, para não acoplar
/// features por uma função de duas linhas.
String formatReportDatePtBr(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Formata um valor em Real, sem depender de `intl`.
String formatReportCurrencyBrl(double value) {
  final String fixed = value.toStringAsFixed(0);
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < fixed.length; i++) {
    final int fromEnd = fixed.length - i;
    if (i > 0 && fromEnd % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(fixed[i]);
  }
  return 'R\$ $buffer';
}
