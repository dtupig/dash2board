/// Situação de vigência de um serviço contratado.
enum ContractStatus {
  active('active'),
  expiring('expiring'),
  expired('expired');

  const ContractStatus(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        ContractStatus.active => 'Ativo',
        ContractStatus.expiring => 'Vencendo',
        ContractStatus.expired => 'Vencido',
      };

  /// Valor desconhecido cai em [ContractStatus.expired] - fail-closed: nunca
  /// mostra como "ativo" um contrato que a origem de dado não confirmou.
  static ContractStatus fromWire(Object? value) {
    if (value is! String) {
      return ContractStatus.expired;
    }
    for (final ContractStatus status in ContractStatus.values) {
      if (status.wireValue == value) {
        return status;
      }
    }
    return ContractStatus.expired;
  }
}

/// Um serviço que o tenant efetivamente contratou - é o que separa "tenho"
/// (aparece em `/relatorios`) de "não tenho" (só aparece no catálogo de
/// demanda). Espelha `/tenants/{tenantId}/contracted_services/{serviceKey}`.
class ContractedService {
  const ContractedService({
    required this.serviceKey,
    required this.contractId,
    required this.startedAt,
    required this.endsAt,
    required this.status,
    required this.deliveriesCount,
    this.lastDeliveryAt,
  });

  final String serviceKey;
  final String contractId;
  final DateTime startedAt;
  final DateTime endsAt;
  final ContractStatus status;
  final DateTime? lastDeliveryAt;
  final int deliveriesCount;

  factory ContractedService.fromMap(Map<String, Object?> map) {
    return ContractedService(
      serviceKey: map['serviceKey'] as String? ?? '',
      contractId: map['contractId'] as String? ?? '',
      startedAt: map['startedAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      endsAt: map['endsAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: ContractStatus.fromWire(map['status']),
      lastDeliveryAt: map['lastDeliveryAt'] as DateTime?,
      deliveriesCount: (map['deliveriesCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'serviceKey': serviceKey,
        'contractId': contractId,
        'startedAt': startedAt,
        'endsAt': endsAt,
        'status': status.wireValue,
        'lastDeliveryAt': lastDeliveryAt,
        'deliveriesCount': deliveriesCount,
      };

  @override
  bool operator ==(Object other) {
    return other is ContractedService &&
        other.serviceKey == serviceKey &&
        other.contractId == contractId &&
        other.startedAt == startedAt &&
        other.endsAt == endsAt &&
        other.status == status &&
        other.lastDeliveryAt == lastDeliveryAt &&
        other.deliveriesCount == deliveriesCount;
  }

  @override
  int get hashCode => Object.hash(
        serviceKey,
        contractId,
        startedAt,
        endsAt,
        status,
        lastDeliveryAt,
        deliveriesCount,
      );

  @override
  String toString() => 'ContractedService($serviceKey, ${status.wireValue})';
}
