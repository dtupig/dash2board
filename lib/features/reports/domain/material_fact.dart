/// Os gatilhos fechados de fato relevante - lista fixa, nunca aberta por
/// texto livre. Cada um tem regra determinística em `MaterialFactEvaluator`.
enum MaterialFactTrigger {
  confirmedCompromise('confirmed_compromise'),
  personalDataExposure('personal_data_exposure'),
  criticalInternetFacing('critical_internet_facing'),
  regulatoryDeadlineRisk('regulatory_deadline_risk'),
  businessContinuityRisk('business_continuity_risk'),
  financialExposureThreshold('financial_exposure_threshold'),
  criticalSupplierRisk('critical_supplier_risk'),
  leakedCorporateCredentials('leaked_corporate_credentials');

  const MaterialFactTrigger(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        MaterialFactTrigger.confirmedCompromise => 'Comprometimento ativo',
        MaterialFactTrigger.personalDataExposure => 'Exposição de dado pessoal',
        MaterialFactTrigger.criticalInternetFacing =>
          'Achado crítico exposto à internet',
        MaterialFactTrigger.regulatoryDeadlineRisk =>
          'Prazo regulatório em risco',
        MaterialFactTrigger.businessContinuityRisk =>
          'Risco de continuidade de negócio',
        MaterialFactTrigger.financialExposureThreshold =>
          'Exposição financeira acima do limite',
        MaterialFactTrigger.criticalSupplierRisk =>
          'Fornecedor crítico com risco não tratado',
        MaterialFactTrigger.leakedCorporateCredentials =>
          'Credencial corporativa vazada',
      };

  static MaterialFactTrigger? fromWire(Object? value) {
    for (final MaterialFactTrigger t in MaterialFactTrigger.values) {
      if (t.wireValue == value) {
        return t;
      }
    }
    return null;
  }
}

/// Um fato relevante - o que leva um relatório à visão do board, mesmo sem
/// ele abrir nem aprovar nada.
class MaterialFact {
  const MaterialFact({
    required this.trigger,
    required this.title,
    required this.consequence,
    required this.detectedAt,
    this.estimatedExposure,
    required this.decisionRequired,
  });

  final MaterialFactTrigger trigger;

  /// Título em linguagem de negócio - o board nunca lê o nome técnico do
  /// gatilho.
  final String title;

  /// O que acontece se nada for feito.
  final String consequence;
  final DateTime detectedAt;

  /// Exposição estimada em Real, quando aplicável.
  final double? estimatedExposure;
  final bool decisionRequired;

  factory MaterialFact.fromMap(Map<String, Object?> map) {
    return MaterialFact(
      trigger: MaterialFactTrigger.fromWire(map['trigger']) ??
          MaterialFactTrigger.confirmedCompromise,
      title: map['title'] as String? ?? '',
      consequence: map['consequence'] as String? ?? '',
      detectedAt: map['detectedAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      estimatedExposure: (map['estimatedExposure'] as num?)?.toDouble(),
      decisionRequired: map['decisionRequired'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'trigger': trigger.wireValue,
        'title': title,
        'consequence': consequence,
        'detectedAt': detectedAt,
        'estimatedExposure': estimatedExposure,
        'decisionRequired': decisionRequired,
      };

  @override
  bool operator ==(Object other) {
    return other is MaterialFact &&
        other.trigger == trigger &&
        other.title == title &&
        other.consequence == consequence &&
        other.detectedAt == detectedAt &&
        other.estimatedExposure == estimatedExposure &&
        other.decisionRequired == decisionRequired;
  }

  @override
  int get hashCode => Object.hash(
        trigger,
        title,
        consequence,
        detectedAt,
        estimatedExposure,
        decisionRequired,
      );
}
