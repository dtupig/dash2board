/// Valor monetário em Real, com separador de milhar manual (ex.: "R$
/// 4.200.000"). Sem `intl`/`NumberFormat`, pelo mesmo motivo das outras
/// formatações deste diretório: determinístico em teste, sem depender de
/// locale carregado em tempo de execução.
String formatCurrencyBrl(num value) {
  final int rounded = value.round();
  final String digits = rounded.abs().toString();
  final StringBuffer grouped = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final int remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) {
      grouped.write('.');
    }
    grouped.write(digits[i]);
  }
  final String sign = rounded < 0 ? '-' : '';
  return '${sign}R\$ $grouped';
}

/// Percentual arredondado de `numerator/denominator` (ex.: 5/6 -> "83%").
/// `denominator == 0` é "sem dados suficientes", não uma divisão por zero
/// disfarçada de 0% - por isso retorna `null`.
String? formatSharePercent(int numerator, int denominator) {
  if (denominator == 0) {
    return null;
  }
  return '${((numerator / denominator) * 100).round()}%';
}

/// Valor monetário compacto em Real (ex.: "R\$ 4,2 mi", "R\$ 950 mil"),
/// para rótulos com pouco espaço (barra do painel do board). Uma casa
/// decimal com vírgula (pt-BR), nunca ponto.
String formatCurrencyCompactBrl(num value) {
  final num magnitude = value.abs();
  final String sign = value < 0 ? '-' : '';
  if (magnitude >= 1000000) {
    final String millions =
        (magnitude / 1000000).toStringAsFixed(1).replaceAll('.', ',');
    return '${sign}R\$ $millions mi';
  }
  if (magnitude >= 1000) {
    final String thousands = (magnitude / 1000).toStringAsFixed(0);
    return '${sign}R\$ $thousands mil';
  }
  return '${sign}R\$ ${magnitude.toStringAsFixed(0)}';
}
