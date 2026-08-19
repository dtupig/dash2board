/// Formata uma data no padrão dd/mm/aaaa.
///
/// Não usa `intl`/`DateFormat` de propósito: evita depender de locale
/// carregado em tempo de execução (o app já usa esse mesmo padrão manual em
/// `trend_line_chart.dart`), o que também deixa os testes de widget
/// determinísticos sem precisar inicializar dados de locale.
String formatDatePtBr(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Um controle é considerado com revisão vencida quando já se passou mais de
/// um ano desde a última revisão.
///
/// Premissa assumida: o modelo de dados guarda apenas `lastReviewedAt` (um
/// carimbo, não um prazo explícito). Cadência anual é o padrão mais comum em
/// auditoria de compliance (ISO 27001, PCI DSS), então usamos isso como a
/// regra de vencimento até existir um campo de prazo dedicado no backend.
///
/// Nota: os chamadores passam `DateTime.now()` (data real) contra
/// `lastReviewedAt` do [MockStrategicRepository], que nasce de uma âncora
/// fixa (`2026-08-01`). A KPI "revisão vencida" ficará em 0 enquanto o
/// relógio real estiver perto da âncora, mas vai subir sozinha - sem
/// nenhuma mudança de código - conforme o tempo real se afasta dela.
bool isReviewOverdue(DateTime lastReviewedAt, DateTime now) {
  final DateTime dueDate = DateTime(
    lastReviewedAt.year + 1,
    lastReviewedAt.month,
    lastReviewedAt.day,
  );
  return now.isAfter(dueDate);
}
