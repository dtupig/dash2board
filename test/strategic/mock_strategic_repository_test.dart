import 'package:elytron_dash2board/features/strategic/data/mock_strategic_repository.dart';
import 'package:elytron_dash2board/features/strategic/domain/compliance_control.dart';
import 'package:elytron_dash2board/features/strategic/domain/insight_item.dart';
import 'package:elytron_dash2board/features/strategic/domain/posture_index.dart';
import 'package:elytron_dash2board/features/strategic/domain/posture_snapshot.dart';
import 'package:elytron_dash2board/features/strategic/domain/risk_item.dart';
import 'package:elytron_dash2board/features/strategic/domain/security_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String tenantId = 'tenant-demo';

  test('histórico de postura tem 12 pontos e mediana de setor 68', () async {
    final MockStrategicRepository repository = MockStrategicRepository();
    final List<PostureSnapshot> history =
        await repository.watchPostureHistory(tenantId).first;

    expect(history.length, 12);
    expect(
      history.every((PostureSnapshot snapshot) => snapshot.peerMedian == 68),
      isTrue,
    );
    expect(history.last.score, 72);

    // A série representa o índice GERAL mês a mês, não uma trilha por
    // domínio (ver comentário em `MockStrategicRepository.watchPostureHistory`).
    // Fixamos essa expectativa aqui de propósito: se um dia a tela de
    // tendência passar a interpretar `domain` por ponto, este teste falha
    // em vez de o rótulo do gráfico silenciosamente sair errado.
    expect(
      history.every(
        (PostureSnapshot snapshot) => snapshot.domain == SecurityDomain.appsec,
      ),
      isTrue,
    );
  });

  test('índice geral de hoje é 72, contra mediana de setor 68', () async {
    final MockStrategicRepository repository = MockStrategicRepository();
    final PostureIndex index =
        await repository.watchPostureIndex(tenantId).first;

    expect(index.overallScore, 72);
    expect(index.peerMedian, 68);
  });

  test('duas execuções seguidas produzem exatamente os mesmos dados', () async {
    final MockStrategicRepository first = MockStrategicRepository();
    final MockStrategicRepository second = MockStrategicRepository();

    final PostureIndex indexA = await first.watchPostureIndex(tenantId).first;
    final PostureIndex indexB = await second.watchPostureIndex(tenantId).first;
    expect(indexA, indexB);

    final List<PostureSnapshot> historyA =
        await first.watchPostureHistory(tenantId).first;
    final List<PostureSnapshot> historyB =
        await second.watchPostureHistory(tenantId).first;
    expect(historyA, historyB);
  });

  test('watchCompliance traz os 24 controles distribuídos nos frameworks',
      () async {
    final MockStrategicRepository repository = MockStrategicRepository();
    final List<ComplianceControl> all =
        await repository.watchCompliance(tenantId).first;
    expect(all.length, 24);

    final List<ComplianceControl> onlyLgpd = await repository
        .watchCompliance(tenantId, framework: ComplianceFramework.lgpd)
        .first;
    expect(onlyLgpd.length, 6);
    expect(
      onlyLgpd.every(
        (ComplianceControl c) => c.framework == ComplianceFramework.lgpd,
      ),
      isTrue,
    );
  });

  test('watchTopRisks respeita o limite pedido', () async {
    final MockStrategicRepository repository = MockStrategicRepository();
    final List<RiskItem> risks =
        await repository.watchTopRisks(tenantId, limit: 3).first;
    expect(risks.length, 3);
  });

  test('watchInsights traz os 8 insights com 3 marcados como benchmark',
      () async {
    final MockStrategicRepository repository = MockStrategicRepository();
    final List<InsightItem> insights =
        await repository.watchInsights(tenantId).first;
    expect(insights.length, 8);
    expect(
      insights.where((InsightItem i) => i.isBenchmark).length,
      3,
    );
  });
}
