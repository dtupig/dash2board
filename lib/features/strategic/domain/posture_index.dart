import 'security_domain.dart';

bool _sameDomainMap(Map<SecurityDomain, int> a, Map<SecurityDomain, int> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final MapEntry<SecurityDomain, int> entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _hashDomainMap(Map<SecurityDomain, int> map) => Object.hashAllUnordered(
      map.entries.map(
        (MapEntry<SecurityDomain, int> e) => Object.hash(e.key, e.value),
      ),
    );

/// Sentido da variação do índice de postura em relação ao período anterior.
enum TrendDirection {
  /// Índice subiu.
  up,

  /// Índice caiu.
  down,

  /// Índice permaneceu igual.
  flat,
}

/// Índice de postura consolidado do tenant, exibido no topo do painel do
/// CISO. É o resumo de "hoje"; a série histórica vive em [PostureSnapshot]
/// através de `StrategicRepository.watchPostureHistory`.
class PostureIndex {
  const PostureIndex({
    required this.overallScore,
    required this.previousScore,
    required this.capturedAt,
    required this.byDomain,
    required this.peerMedian,
    this.byDomainDelta30d = const <SecurityDomain, int>{},
  });

  /// Estado neutro, usado quando ainda não há tenant resolvido.
  factory PostureIndex.empty() => PostureIndex(
        overallScore: 0,
        previousScore: 0,
        capturedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        byDomain: const <SecurityDomain, int>{},
        peerMedian: 0,
      );

  /// Nota geral de 0 a 100.
  final int overallScore;

  /// Nota geral do período anterior, usada para o indicador de tendência.
  final int previousScore;

  /// Instante em que este índice foi calculado.
  final DateTime capturedAt;

  /// Nota por domínio de controle.
  final Map<SecurityDomain, int> byDomain;

  /// Mediana do setor para o mesmo índice geral.
  final int peerMedian;

  /// Variação de cada domínio nos últimos 30 dias - usada só no detalhe de
  /// domínio (`domain_detail_sheet.dart`); um domínio ausente aqui vale 0,
  /// nunca quebra a tela.
  final Map<SecurityDomain, int> byDomainDelta30d;

  /// Variação em pontos em relação ao período anterior.
  int get delta => overallScore - previousScore;

  /// Sentido da variação, para o ícone de tendência no card do KPI.
  TrendDirection get trendDirection {
    if (delta > 0) {
      return TrendDirection.up;
    }
    if (delta < 0) {
      return TrendDirection.down;
    }
    return TrendDirection.flat;
  }

  /// Domínio com a menor nota — a prioridade de atenção do CISO.
  SecurityDomain? get weakestDomain {
    if (byDomain.isEmpty) {
      return null;
    }
    return byDomain.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  /// Domínio com a maior nota.
  SecurityDomain? get strongestDomain {
    if (byDomain.isEmpty) {
      return null;
    }
    return byDomain.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  PostureIndex copyWith({
    int? overallScore,
    int? previousScore,
    DateTime? capturedAt,
    Map<SecurityDomain, int>? byDomain,
    int? peerMedian,
    Map<SecurityDomain, int>? byDomainDelta30d,
  }) {
    return PostureIndex(
      overallScore: overallScore ?? this.overallScore,
      previousScore: previousScore ?? this.previousScore,
      capturedAt: capturedAt ?? this.capturedAt,
      byDomain: byDomain ?? this.byDomain,
      peerMedian: peerMedian ?? this.peerMedian,
      byDomainDelta30d: byDomainDelta30d ?? this.byDomainDelta30d,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostureIndex &&
        other.overallScore == overallScore &&
        other.previousScore == previousScore &&
        other.capturedAt == capturedAt &&
        other.peerMedian == peerMedian &&
        _sameDomainMap(byDomain, other.byDomain) &&
        _sameDomainMap(byDomainDelta30d, other.byDomainDelta30d);
  }

  @override
  int get hashCode => Object.hash(
        overallScore,
        previousScore,
        capturedAt,
        peerMedian,
        _hashDomainMap(byDomain),
        _hashDomainMap(byDomainDelta30d),
      );

  @override
  String toString() =>
      'PostureIndex(overall: $overallScore, anterior: $previousScore, '
      'mediana: $peerMedian)';
}
