import 'security_domain.dart';

/// Frameworks de compliance cobertos pelo painel do CISO.
enum ComplianceFramework {
  iso27001('ISO27001'),
  nistCsf('NIST_CSF'),
  lgpd('LGPD'),
  pciDss('PCI_DSS');

  const ComplianceFramework(this.wireValue);

  /// Valor persistido no Firestore (`docs/01_MODELO_DADOS_FIRESTORE.md`).
  final String wireValue;

  /// Rótulo em pt-BR exibido nos filtros e cabeçalhos de seção.
  String get label => switch (this) {
        ComplianceFramework.iso27001 => 'ISO 27001',
        ComplianceFramework.nistCsf => 'NIST CSF',
        ComplianceFramework.lgpd => 'LGPD',
        ComplianceFramework.pciDss => 'PCI DSS',
      };

  /// Converte o valor vindo do backend. Não é uma decisão de acesso — apenas
  /// precisa de um valor estável para não quebrar o filtro por framework.
  static ComplianceFramework fromWire(Object? value) {
    if (value is! String) {
      return ComplianceFramework.iso27001;
    }
    for (final ComplianceFramework framework in ComplianceFramework.values) {
      if (framework.wireValue == value) {
        return framework;
      }
    }
    return ComplianceFramework.iso27001;
  }
}

/// Situação de um controle de compliance.
enum ControlStatus {
  compliant('compliant'),
  partial('partial'),
  gap('gap');

  const ControlStatus(this.wireValue);

  final String wireValue;

  /// Rótulo em pt-BR exibido no chip de status.
  String get label => switch (this) {
        ControlStatus.compliant => 'Conforme',
        ControlStatus.partial => 'Parcial',
        ControlStatus.gap => 'Lacuna',
      };

  /// Converte o valor vindo do backend. Diferente de [ComplianceFramework],
  /// aqui o fallback É uma decisão de segurança: um status desconhecido cai
  /// em [ControlStatus.gap], nunca em [ControlStatus.compliant] — o painel
  /// do CISO não pode afirmar conformidade que não conseguiu interpretar.
  static ControlStatus fromWire(Object? value) {
    if (value is! String) {
      return ControlStatus.gap;
    }
    for (final ControlStatus status in ControlStatus.values) {
      if (status.wireValue == value) {
        return status;
      }
    }
    return ControlStatus.gap;
  }
}

/// Um controle de compliance dentro de um framework, com dono e evidência.
///
/// Espelha `compliance/{controlId}` (`docs/01_MODELO_DADOS_FIRESTORE.md`). A
/// conversão de `Timestamp` para [DateTime] acontece na camada de dados.
class ComplianceControl {
  const ComplianceControl({
    required this.framework,
    required this.controlId,
    required this.title,
    required this.status,
    required this.ownerName,
    required this.lastReviewedAt,
    required this.domain,
    this.evidenceUrl,
  });

  final ComplianceFramework framework;
  final String controlId;
  final String title;
  final ControlStatus status;
  final String ownerName;
  final DateTime lastReviewedAt;

  /// Domínio de segurança ao qual este controle está mais associado (ex.:
  /// A.12.6 de vulnerabilidades técnicas → [SecurityDomain.appsec]). Permite
  /// o drill-down do painel de postura por domínio até a lista de controles.
  final SecurityDomain domain;

  final String? evidenceUrl;

  factory ComplianceControl.fromMap(Map<String, Object?> map) {
    return ComplianceControl(
      framework: ComplianceFramework.fromWire(map['framework']),
      controlId: map['controlId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      status: ControlStatus.fromWire(map['status']),
      ownerName: map['ownerName'] as String? ?? '',
      lastReviewedAt: map['lastReviewedAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      domain: SecurityDomain.fromWire(map['domain']),
      evidenceUrl: map['evidenceUrl'] as String?,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'framework': framework.wireValue,
        'controlId': controlId,
        'title': title,
        'status': status.wireValue,
        'ownerName': ownerName,
        'lastReviewedAt': lastReviewedAt,
        'domain': domain.wireValue,
        'evidenceUrl': evidenceUrl,
      };

  ComplianceControl copyWith({
    ComplianceFramework? framework,
    String? controlId,
    String? title,
    ControlStatus? status,
    String? ownerName,
    DateTime? lastReviewedAt,
    SecurityDomain? domain,
    String? evidenceUrl,
  }) {
    return ComplianceControl(
      framework: framework ?? this.framework,
      controlId: controlId ?? this.controlId,
      title: title ?? this.title,
      status: status ?? this.status,
      ownerName: ownerName ?? this.ownerName,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      domain: domain ?? this.domain,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ComplianceControl &&
        other.framework == framework &&
        other.controlId == controlId &&
        other.title == title &&
        other.status == status &&
        other.ownerName == ownerName &&
        other.lastReviewedAt == lastReviewedAt &&
        other.domain == domain &&
        other.evidenceUrl == evidenceUrl;
  }

  @override
  int get hashCode => Object.hash(
        framework,
        controlId,
        title,
        status,
        ownerName,
        lastReviewedAt,
        domain,
        evidenceUrl,
      );

  @override
  String toString() => 'ComplianceControl($controlId, ${status.wireValue})';
}
