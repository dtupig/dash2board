import 'security_domain.dart';

/// Tratamento dado a um risco de negócio.
enum RiskTreatment {
  mitigate('mitigate'),
  transfer('transfer'),
  accept('accept'),
  avoid('avoid');

  const RiskTreatment(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        RiskTreatment.mitigate => 'Mitigar',
        RiskTreatment.transfer => 'Transferir',
        RiskTreatment.accept => 'Aceitar',
        RiskTreatment.avoid => 'Evitar',
      };

  /// Converte o valor vindo do backend. Um valor desconhecido cai em
  /// [RiskTreatment.mitigate] — o tratamento mais conservador para exibição,
  /// nunca em "aceitar" por omissão.
  static RiskTreatment fromWire(Object? value) {
    if (value is! String) {
      return RiskTreatment.mitigate;
    }
    for (final RiskTreatment treatment in RiskTreatment.values) {
      if (treatment.wireValue == value) {
        return treatment;
      }
    }
    return RiskTreatment.mitigate;
  }
}

/// Situação do aceite executivo de um risco.
enum RiskAcceptance {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),

  /// O board não aceitou o risco como está e pediu um plano de mitigação ao
  /// CISO - nem "pendente" (ninguém decidiu ainda) nem "rejeitado" (recusa
  /// sem retorno). É a segunda ação do painel do board ("solicitar plano").
  planRequested('plan_requested');

  const RiskAcceptance(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        RiskAcceptance.pending => 'Pendente',
        RiskAcceptance.accepted => 'Aceito',
        RiskAcceptance.rejected => 'Rejeitado',
        RiskAcceptance.planRequested => 'Plano solicitado',
      };

  /// Um valor desconhecido cai em [RiskAcceptance.pending] — nunca assume
  /// aceite executivo que não foi de fato registrado.
  static RiskAcceptance fromWire(Object? value) {
    if (value is! String) {
      return RiskAcceptance.pending;
    }
    for (final RiskAcceptance acceptance in RiskAcceptance.values) {
      if (acceptance.wireValue == value) {
        return acceptance;
      }
    }
    return RiskAcceptance.pending;
  }
}

/// Risco de negócio traduzido para linguagem executiva.
///
/// Espelha `risks/{id}` (`docs/01_MODELO_DADOS_FIRESTORE.md`). A conversão de
/// `Timestamp` para [DateTime] acontece na camada de dados.
class RiskItem {
  const RiskItem({
    required this.id,
    required this.title,
    required this.businessUnit,
    required this.domain,
    required this.inherentScore,
    required this.residualScore,
    required this.annualLossExpectancy,
    required this.currency,
    required this.treatment,
    required this.acceptance,
    required this.reviewDueAt,
  });

  final String id;

  /// Título em linguagem de negócio, sem jargão técnico.
  final String title;

  final String businessUnit;
  final SecurityDomain domain;

  /// Nota de risco antes de qualquer controle, de 0 a 100.
  final int inherentScore;

  /// Nota de risco após os controles em vigor, de 0 a 100.
  final int residualScore;

  /// Perda anual esperada (ALE), na moeda de [currency].
  final double annualLossExpectancy;

  final String currency;
  final RiskTreatment treatment;
  final RiskAcceptance acceptance;
  final DateTime reviewDueAt;

  factory RiskItem.fromMap(Map<String, Object?> map) {
    return RiskItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      businessUnit: map['businessUnit'] as String? ?? '',
      domain: SecurityDomain.fromWire(map['domain']),
      inherentScore: (map['inherentScore'] as num?)?.toInt() ?? 0,
      residualScore: (map['residualScore'] as num?)?.toInt() ?? 0,
      annualLossExpectancy:
          (map['annualLossExpectancy'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'BRL',
      treatment: RiskTreatment.fromWire(map['treatment']),
      acceptance: RiskAcceptance.fromWire(map['acceptance']),
      reviewDueAt: map['reviewDueAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'businessUnit': businessUnit,
        'domain': domain.wireValue,
        'inherentScore': inherentScore,
        'residualScore': residualScore,
        'annualLossExpectancy': annualLossExpectancy,
        'currency': currency,
        'treatment': treatment.wireValue,
        'acceptance': acceptance.wireValue,
        'reviewDueAt': reviewDueAt,
      };

  RiskItem copyWith({
    String? id,
    String? title,
    String? businessUnit,
    SecurityDomain? domain,
    int? inherentScore,
    int? residualScore,
    double? annualLossExpectancy,
    String? currency,
    RiskTreatment? treatment,
    RiskAcceptance? acceptance,
    DateTime? reviewDueAt,
  }) {
    return RiskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      businessUnit: businessUnit ?? this.businessUnit,
      domain: domain ?? this.domain,
      inherentScore: inherentScore ?? this.inherentScore,
      residualScore: residualScore ?? this.residualScore,
      annualLossExpectancy:
          annualLossExpectancy ?? this.annualLossExpectancy,
      currency: currency ?? this.currency,
      treatment: treatment ?? this.treatment,
      acceptance: acceptance ?? this.acceptance,
      reviewDueAt: reviewDueAt ?? this.reviewDueAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RiskItem &&
        other.id == id &&
        other.title == title &&
        other.businessUnit == businessUnit &&
        other.domain == domain &&
        other.inherentScore == inherentScore &&
        other.residualScore == residualScore &&
        other.annualLossExpectancy == annualLossExpectancy &&
        other.currency == currency &&
        other.treatment == treatment &&
        other.acceptance == acceptance &&
        other.reviewDueAt == reviewDueAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        businessUnit,
        domain,
        inherentScore,
        residualScore,
        annualLossExpectancy,
        currency,
        treatment,
        acceptance,
        reviewDueAt,
      );

  @override
  String toString() => 'RiskItem($id, $businessUnit, ALE: $annualLossExpectancy $currency)';
}
