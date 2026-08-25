/// Como um serviço é entregue ao cliente.
enum DeliveryModel {
  /// Uma execução, com início e fim definidos.
  oneOff('one_off'),

  /// Repete em uma cadência combinada (ex.: trimestral).
  recurring('recurring'),

  /// Rodando o tempo todo, sem uma "entrega final".
  continuous('continuous'),

  /// Capacidade reservada, acionada quando necessário.
  retainer('retainer');

  const DeliveryModel(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        DeliveryModel.oneOff => 'Pontual',
        DeliveryModel.recurring => 'Recorrente',
        DeliveryModel.continuous => 'Contínuo',
        DeliveryModel.retainer => 'Retainer',
      };

  /// Valor desconhecido cai em [DeliveryModel.oneOff] - o modelo mais
  /// simples, nunca assume um compromisso recorrente que não existe.
  static DeliveryModel fromWire(Object? value) {
    if (value is! String) {
      return DeliveryModel.oneOff;
    }
    for (final DeliveryModel model in DeliveryModel.values) {
      if (model.wireValue == value) {
        return model;
      }
    }
    return DeliveryModel.oneOff;
  }
}
