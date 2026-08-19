import 'security_domain.dart';

/// Fotografia do índice de postura de um domínio em um instante.
///
/// Espelha `posture_snapshots/{id}` (`docs/01_MODELO_DADOS_FIRESTORE.md`).
/// A conversão de `Timestamp` para [DateTime] acontece na camada de dados,
/// nunca aqui: este arquivo não importa Flutter nem Firebase.
class PostureSnapshot {
  const PostureSnapshot({
    required this.domain,
    required this.score,
    required this.capturedAt,
    required this.peerMedian,
    required this.delta30d,
  });

  /// Domínio de controle ao qual este ponto se refere.
  final SecurityDomain domain;

  /// Nota de 0 a 100.
  final int score;

  /// Instante em que a nota foi calculada.
  final DateTime capturedAt;

  /// Mediana do mesmo domínio entre empresas do setor.
  final int peerMedian;

  /// Variação em relação a 30 dias antes.
  final int delta30d;

  /// Constrói a partir de um mapa já normalizado (datas como [DateTime]).
  factory PostureSnapshot.fromMap(Map<String, Object?> map) {
    return PostureSnapshot(
      domain: SecurityDomain.fromWire(map['domain']),
      score: (map['score'] as num?)?.toInt() ?? 0,
      capturedAt: map['capturedAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      peerMedian: (map['peerMedian'] as num?)?.toInt() ?? 0,
      delta30d: (map['delta30d'] as num?)?.toInt() ?? 0,
    );
  }

  /// Serializa para um mapa simples (datas como [DateTime]).
  Map<String, Object?> toMap() => <String, Object?>{
        'domain': domain.wireValue,
        'score': score,
        'capturedAt': capturedAt,
        'peerMedian': peerMedian,
        'delta30d': delta30d,
      };

  PostureSnapshot copyWith({
    SecurityDomain? domain,
    int? score,
    DateTime? capturedAt,
    int? peerMedian,
    int? delta30d,
  }) {
    return PostureSnapshot(
      domain: domain ?? this.domain,
      score: score ?? this.score,
      capturedAt: capturedAt ?? this.capturedAt,
      peerMedian: peerMedian ?? this.peerMedian,
      delta30d: delta30d ?? this.delta30d,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostureSnapshot &&
        other.domain == domain &&
        other.score == score &&
        other.capturedAt == capturedAt &&
        other.peerMedian == peerMedian &&
        other.delta30d == delta30d;
  }

  @override
  int get hashCode =>
      Object.hash(domain, score, capturedAt, peerMedian, delta30d);

  @override
  String toString() =>
      'PostureSnapshot(${domain.wireValue}: $score em $capturedAt)';
}
