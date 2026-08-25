/// Por que a solicitação está sendo aberta - existe para que a proposta que
/// volta da Elytron não seja genérica.
enum RequestDriver {
  auditFinding('audit_finding'),
  regulatory('regulatory'),
  incident('incident'),
  newProject('new_project'),
  clientDemand('client_demand'),
  internalInitiative('internal_initiative');

  const RequestDriver(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        RequestDriver.auditFinding => 'Achado de auditoria',
        RequestDriver.regulatory => 'Exigência regulatória',
        RequestDriver.incident => 'Consequência de um incidente',
        RequestDriver.newProject => 'Novo projeto ou produto',
        RequestDriver.clientDemand => 'Exigência de um cliente',
        RequestDriver.internalInitiative => 'Iniciativa interna',
      };

  /// Valor desconhecido cai em [RequestDriver.internalInitiative] - o motivo
  /// mais neutro, nunca inventa um achado de auditoria ou incidente que não
  /// foi declarado.
  static RequestDriver fromWire(Object? value) {
    if (value is! String) {
      return RequestDriver.internalInitiative;
    }
    for (final RequestDriver driver in RequestDriver.values) {
      if (driver.wireValue == value) {
        return driver;
      }
    }
    return RequestDriver.internalInitiative;
  }
}
