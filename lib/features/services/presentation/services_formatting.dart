/// Formata uma data no padrão dd/mm/aaaa, sem depender de `intl`/locale em
/// tempo de execução - mesma convenção de
/// `strategic/presentation/compliance_formatting.dart`, duplicada aqui para
/// não acoplar o módulo de serviços ao de estratégia por uma função de duas
/// linhas.
String formatServiceDatePtBr(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
