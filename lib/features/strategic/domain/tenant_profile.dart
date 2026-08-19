/// Fatos sobre o tenant como organização - não sobre um controle, risco ou
/// insight específico. Hoje só o que o painel do board precisa: receita
/// anual (para expressar exposição como percentual) e o executivo dono de
/// cada unidade de negócio (para que todo risco tenha um nome
/// responsável, nunca "ninguém").
///
/// Espelha campos do documento `tenants/{tenantId}`
/// (`docs/01_MODELO_DADOS_FIRESTORE.md`).
class TenantProfile {
  const TenantProfile({
    required this.annualRevenue,
    required this.businessUnitOwners,
    required this.previousQuarterAle,
  });

  factory TenantProfile.empty() => const TenantProfile(
        annualRevenue: 0,
        businessUnitOwners: <String, String>{},
        previousQuarterAle: 0,
      );

  /// Receita anual do tenant, na mesma moeda dos riscos (`RiskItem.currency`,
  /// hoje sempre BRL).
  final double annualRevenue;

  /// Nome (e cargo) do executivo dono de cada unidade de negócio, chaveado
  /// por `RiskItem.businessUnit`.
  final Map<String, String> businessUnitOwners;

  /// Soma da perda anual esperada (ALE) de todos os riscos, um trimestre
  /// atrás - usado só para o selo de variação trimestral do painel do
  /// board. Pré-calculado (o cliente nunca soma o histórico de riscos).
  final double previousQuarterAle;

  /// Nome do dono da unidade, ou um rótulo explícito de ausência - nunca uma
  /// string vazia. Risco sem dono nomeado não gera decisão.
  String ownerFor(String businessUnit) =>
      businessUnitOwners[businessUnit] ?? 'Sem executivo responsável definido';

  factory TenantProfile.fromMap(Map<String, Object?> map) {
    final Map<String, dynamic> ownersRaw =
        (map['businessUnitOwners'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};
    return TenantProfile(
      annualRevenue: (map['annualRevenue'] as num?)?.toDouble() ?? 0,
      businessUnitOwners: <String, String>{
        for (final MapEntry<String, dynamic> entry in ownersRaw.entries)
          entry.key: entry.value as String? ?? '',
      },
      previousQuarterAle: (map['previousQuarterAle'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'annualRevenue': annualRevenue,
        'businessUnitOwners': businessUnitOwners,
        'previousQuarterAle': previousQuarterAle,
      };

  @override
  bool operator ==(Object other) {
    if (other is! TenantProfile ||
        other.annualRevenue != annualRevenue ||
        other.previousQuarterAle != previousQuarterAle) {
      return false;
    }
    if (other.businessUnitOwners.length != businessUnitOwners.length) {
      return false;
    }
    for (final MapEntry<String, String> entry in businessUnitOwners.entries) {
      if (other.businessUnitOwners[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        annualRevenue,
        previousQuarterAle,
        Object.hashAllUnordered(
          businessUnitOwners.entries
              .map((MapEntry<String, String> e) => Object.hash(e.key, e.value)),
        ),
      );

  @override
  String toString() =>
      'TenantProfile(receita: $annualRevenue, unidades: ${businessUnitOwners.length})';
}
