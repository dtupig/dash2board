/// Helpers de data compartilhados pelos dados de demonstração da persona
/// estratégica - todos derivam de uma data-âncora fixa, nunca de
/// `DateTime.now()`, para que a demonstração seja reproduzível. Isolado
/// para não duplicar a mesma conta em cada arquivo `mock_strategic_*.dart`.
library;

DateTime monthsBefore(DateTime from, int months) =>
    DateTime.utc(from.year, from.month - months, from.day);

DateTime daysBefore(DateTime from, int days) =>
    from.subtract(Duration(days: days));

DateTime daysAfter(DateTime from, int days) => from.add(Duration(days: days));
