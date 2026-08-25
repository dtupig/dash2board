/// Decisão do CISO sobre uma solicitação - aprovada ou rejeitada.
enum ApprovalDecision {
  approved('approved'),
  rejected('rejected');

  const ApprovalDecision(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        ApprovalDecision.approved => 'Aprovada',
        ApprovalDecision.rejected => 'Rejeitada',
      };

  /// Valor desconhecido cai em [ApprovalDecision.rejected] - fail-closed:
  /// nunca trata um registro ambíguo como aprovação.
  static ApprovalDecision fromWire(Object? value) {
    if (value is! String) {
      return ApprovalDecision.rejected;
    }
    for (final ApprovalDecision decision in ApprovalDecision.values) {
      if (decision.wireValue == value) {
        return decision;
      }
    }
    return ApprovalDecision.rejected;
  }
}

/// Registro imutável de uma decisão de aprovação sobre uma [ServiceRequest].
///
/// Existe até para a auto-aprovação do `strategic` quando ele mesmo abre a
/// solicitação (seção C do prompt 10) - a auditoria não aceita um buraco de
/// "quem aprovou" só porque quem aprovou também é quem abriu.
class ApprovalRecord {
  const ApprovalRecord({
    required this.decidedByUid,
    required this.decidedByName,
    required this.decidedAt,
    required this.decision,
    this.note = '',
    this.isSelfApproval = false,
  });

  final String decidedByUid;
  final String decidedByName;
  final DateTime decidedAt;
  final ApprovalDecision decision;

  /// Obrigatória na rejeição - a interface e o domínio impedem uma rejeição
  /// sem nota (`RequestPolicy` e `request_inbox_screen.dart`).
  final String note;

  /// Verdadeiro quando `strategic` abriu e aprovou a própria solicitação -
  /// marcado explicitamente para que a trilha de auditoria nunca confunda
  /// isso com uma aprovação de terceiro.
  final bool isSelfApproval;

  factory ApprovalRecord.fromMap(Map<String, Object?> map) {
    return ApprovalRecord(
      decidedByUid: map['decidedByUid'] as String? ?? '',
      decidedByName: map['decidedByName'] as String? ?? '',
      decidedAt: map['decidedAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      decision: ApprovalDecision.fromWire(map['decision']),
      note: map['note'] as String? ?? '',
      isSelfApproval: map['isSelfApproval'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'decidedByUid': decidedByUid,
        'decidedByName': decidedByName,
        'decidedAt': decidedAt,
        'decision': decision.wireValue,
        'note': note,
        'isSelfApproval': isSelfApproval,
      };

  @override
  bool operator ==(Object other) {
    return other is ApprovalRecord &&
        other.decidedByUid == decidedByUid &&
        other.decidedByName == decidedByName &&
        other.decidedAt == decidedAt &&
        other.decision == decision &&
        other.note == note &&
        other.isSelfApproval == isSelfApproval;
  }

  @override
  int get hashCode => Object.hash(
        decidedByUid,
        decidedByName,
        decidedAt,
        decision,
        note,
        isSelfApproval,
      );

  @override
  String toString() =>
      'ApprovalRecord(${decision.wireValue} por $decidedByName)';
}
