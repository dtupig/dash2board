import '../../domain/posture_index.dart';
import '../../domain/posture_snapshot.dart';
import '../../domain/security_domain.dart';
import 'mock_strategic_dates.dart';

/// Índice geral mês a mês, dos 12 meses anteriores até hoje. Melhora
/// consistente (64 → 72), com um recuo nos meses 7 e 8 do período.
const List<int> _monthlyOverallScores = <int>[
  64,
  65,
  66,
  67,
  68,
  69,
  66,
  65,
  68,
  70,
  71,
  72,
];

const int _peerMedian = 68;

const Map<SecurityDomain, int> _byDomainToday = <SecurityDomain, int>{
  SecurityDomain.identity: 81,
  SecurityDomain.endpoint: 76,
  SecurityDomain.cloud: 63,
  SecurityDomain.appsec: 58,
  SecurityDomain.data: 74,
  SecurityDomain.thirdParty: 55,
};

/// Variação de cada domínio nos últimos 30 dias - histórico curto usado só
/// no detalhe de domínio, não no gráfico de tendência (que é o índice
/// geral). Appsec e terceiros pioraram no mês, mesmo com a média geral
/// melhorando - é exatamente o tipo de contraste que justifica o
/// drill-down por domínio em vez de só olhar o número geral.
const Map<SecurityDomain, int> _byDomainDelta30d = <SecurityDomain, int>{
  SecurityDomain.identity: 2,
  SecurityDomain.endpoint: 1,
  SecurityDomain.cloud: 3,
  SecurityDomain.appsec: -2,
  SecurityDomain.data: 1,
  SecurityDomain.thirdParty: -1,
};

PostureIndex buildPostureIndex(DateTime anchor) {
  final int previousMonthScore =
      _monthlyOverallScores[_monthlyOverallScores.length - 2];
  return PostureIndex(
    overallScore: _monthlyOverallScores.last,
    previousScore: previousMonthScore,
    capturedAt: anchor,
    byDomain: _byDomainToday,
    peerMedian: _peerMedian,
    byDomainDelta30d: _byDomainDelta30d,
  );
}

List<PostureSnapshot> buildPostureHistory(DateTime anchor, {int months = 12}) {
  final int count = months.clamp(0, _monthlyOverallScores.length).toInt();
  final int start = _monthlyOverallScores.length - count;
  return <PostureSnapshot>[
    for (int i = start; i < _monthlyOverallScores.length; i++)
      PostureSnapshot(
        // A série é o índice GERAL mês a mês, não uma trilha por domínio: o
        // campo `domain` só existe porque o modelo espelha o schema de
        // `posture_snapshots` do Firestore. Marcamos com o domínio que mais
        // pesa na narrativa do período (appsec), sem que a tela de
        // tendência precise interpretar esse campo.
        domain: SecurityDomain.appsec,
        score: _monthlyOverallScores[i],
        capturedAt: monthsBefore(anchor, _monthlyOverallScores.length - 1 - i),
        peerMedian: _peerMedian,
        delta30d: i == 0
            ? 0
            : _monthlyOverallScores[i] - _monthlyOverallScores[i - 1],
      ),
  ];
}
