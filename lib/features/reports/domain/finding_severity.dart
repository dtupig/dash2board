/// Severidade de um achado técnico - alinhada a CVSS v3.1/v4.0.
///
/// Domínio puro; a apresentação visual (cor, ícone) mapeia isto para
/// `ChartSeverityLevel` na camada de apresentação, nunca o contrário.
enum FindingSeverity {
  critical('critical'),
  high('high'),
  medium('medium'),
  low('low');

  const FindingSeverity(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        FindingSeverity.critical => 'Crítico',
        FindingSeverity.high => 'Alto',
        FindingSeverity.medium => 'Médio',
        FindingSeverity.low => 'Baixo',
      };

  static FindingSeverity fromWire(Object? value) {
    for (final FindingSeverity s in FindingSeverity.values) {
      if (s.wireValue == value) {
        return s;
      }
    }
    return FindingSeverity.low;
  }
}

/// Ambiente onde um achado foi observado - muda a severidade percebida
/// (D-27, gap #9: achado em homologação não tem o mesmo peso que em
/// produção).
enum FindingEnvironment {
  production('production'),
  staging('staging'),
  homolog('homolog');

  const FindingEnvironment(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        FindingEnvironment.production => 'Produção',
        FindingEnvironment.staging => 'Staging',
        FindingEnvironment.homolog => 'Homologação',
      };

  static FindingEnvironment? fromWire(Object? value) {
    for (final FindingEnvironment e in FindingEnvironment.values) {
      if (e.wireValue == value) {
        return e;
      }
    }
    return null;
  }
}
