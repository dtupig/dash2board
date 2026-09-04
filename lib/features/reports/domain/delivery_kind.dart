/// Tipo de entrega de um relatório (D-27, gap #11).
///
/// Validado contra caso real: uma disciplina pode entregar um achado único,
/// crítico, antes do relatório final do serviço - um "relatório
/// extraordinário". Sem este marcador, essa entrega ficaria indistinguível
/// de um relatório final normal.
enum DeliveryKind {
  /// Entrega dentro do ciclo normal do serviço contratado.
  scheduled('scheduled'),

  /// Entrega antecipada e parcial, fora do ciclo normal - tipicamente um
  /// achado crítico único que não pode esperar o relatório consolidado.
  interim('interim');

  const DeliveryKind(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        DeliveryKind.scheduled => 'Entrega programada',
        DeliveryKind.interim => 'Entrega extraordinária',
      };

  static DeliveryKind fromWire(Object? value) {
    for (final DeliveryKind k in DeliveryKind.values) {
      if (k.wireValue == value) {
        return k;
      }
    }
    return DeliveryKind.scheduled;
  }
}
