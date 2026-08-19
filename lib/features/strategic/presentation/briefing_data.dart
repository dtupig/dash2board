import '../domain/compliance_control.dart';
import '../domain/posture_index.dart';
import '../domain/posture_snapshot.dart';
import '../domain/risk_item.dart';
import '../domain/security_domain.dart';

/// Todo o dado já resolvido e ordenado que o briefing executivo de uma
/// página precisa - o mesmo objeto alimenta o preview em Flutter (tela) e o
/// PDF (`pdf`/`printing`), para que as duas renderizações nunca divirjam.
///
/// Pura Dart: não importa Flutter. É um recorte computado a partir dos
/// domínios já carregados (`PostureIndex`, `ComplianceControl`, `RiskItem`),
/// não uma entidade espelhada 1:1 do Firestore.
class BriefingData {
  const BriefingData({
    required this.overallScore,
    required this.previousScore,
    required this.peerMedian,
    required this.generatedAt,
    required this.weakestDomains,
    required this.topExposures,
    required this.pendingDecisions,
    required this.compliancePercentByFramework,
    required this.isMockData,
    required this.tenantId,
  });

  factory BriefingData.build({
    required PostureIndex postureIndex,
    required List<PostureSnapshot> postureHistory,
    required List<ComplianceControl> complianceControls,
    required List<RiskItem> risks,
    required bool isMockData,
    required String tenantId,
    required DateTime generatedAt,
  }) {
    final List<MapEntry<SecurityDomain, int>> byScoreAsc =
        postureIndex.byDomain.entries.toList(growable: false)
          ..sort((a, b) => a.value.compareTo(b.value));

    final List<RiskItem> byAleDesc = List<RiskItem>.of(risks)
      ..sort(
          (a, b) => b.annualLossExpectancy.compareTo(a.annualLossExpectancy));

    final Map<ComplianceFramework, int?> percentByFramework =
        <ComplianceFramework, int?>{
      for (final ComplianceFramework framework in ComplianceFramework.values)
        framework: _percentCompliant(complianceControls, framework),
    };

    // A variação da seção 1 é de 12 MESES (o ponto mais antigo do
    // histórico), não a `previousScore` de `PostureIndex` - que é só o mês
    // anterior. `postureHistory` chega ordenada do mais antigo para o mais
    // recente (contrato de `StrategicRepository.watchPostureHistory`).
    final int twelveMonthsAgoScore = postureHistory.isEmpty
        ? postureIndex.overallScore
        : postureHistory.first.score;

    return BriefingData(
      overallScore: postureIndex.overallScore,
      previousScore: twelveMonthsAgoScore,
      peerMedian: postureIndex.peerMedian,
      generatedAt: generatedAt,
      weakestDomains: byScoreAsc.take(2).toList(growable: false),
      topExposures: byAleDesc.take(3).toList(growable: false),
      pendingDecisions: risks
          .where((RiskItem r) => r.acceptance == RiskAcceptance.pending)
          .toList(growable: false),
      compliancePercentByFramework: percentByFramework,
      isMockData: isMockData,
      tenantId: tenantId,
    );
  }

  final int overallScore;

  /// Índice de postura de 12 meses atrás (o ponto mais antigo do
  /// histórico), usado para a variação da seção 1 - não confundir com
  /// `PostureIndex.previousScore`, que é só o mês anterior.
  final int previousScore;
  final int peerMedian;
  final DateTime generatedAt;

  /// Os dois domínios de menor nota, em ordem crescente (o mais fraco
  /// primeiro).
  final List<MapEntry<SecurityDomain, int>> weakestDomains;

  /// As três maiores exposições financeiras, em ordem decrescente de ALE
  /// (perda anual esperada).
  final List<RiskItem> topExposures;

  /// Riscos que ainda dependem de decisão do comitê (`acceptance ==
  /// pending`).
  final List<RiskItem> pendingDecisions;

  /// Percentual de controles conformes por framework. `null` quando o
  /// tenant não tem nenhum controle cadastrado naquele framework ainda.
  final Map<ComplianceFramework, int?> compliancePercentByFramework;

  final bool isMockData;
  final String tenantId;

  int get delta => overallScore - previousScore;

  static int? _percentCompliant(
    List<ComplianceControl> controls,
    ComplianceFramework framework,
  ) {
    final List<ComplianceControl> inFramework = controls
        .where((ComplianceControl c) => c.framework == framework)
        .toList(growable: false);
    if (inFramework.isEmpty) {
      return null;
    }
    final int compliant = inFramework
        .where((ComplianceControl c) => c.status == ControlStatus.compliant)
        .length;
    return ((compliant / inFramework.length) * 100).round();
  }
}
