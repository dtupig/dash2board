import 'package:elytron_dash2board/features/strategic/domain/posture_index.dart';
import 'package:elytron_dash2board/features/strategic/domain/security_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final PostureIndex index = PostureIndex(
    overallScore: 72,
    previousScore: 71,
    capturedAt: DateTime.utc(2026, 8, 1),
    peerMedian: 68,
    byDomain: const <SecurityDomain, int>{
      SecurityDomain.identity: 81,
      SecurityDomain.endpoint: 76,
      SecurityDomain.cloud: 63,
      SecurityDomain.appsec: 58,
      SecurityDomain.data: 74,
      SecurityDomain.thirdParty: 55,
    },
  );

  test('delta é a diferença entre a nota atual e a anterior', () {
    expect(index.delta, 1);
  });

  test('trendDirection reflete o sinal do delta', () {
    expect(index.trendDirection, TrendDirection.up);
    expect(
        index.copyWith(previousScore: 72).trendDirection, TrendDirection.flat);
    expect(
        index.copyWith(previousScore: 80).trendDirection, TrendDirection.down);
  });

  test('weakestDomain e strongestDomain apontam para os extremos', () {
    expect(index.weakestDomain, SecurityDomain.thirdParty);
    expect(index.strongestDomain, SecurityDomain.identity);
  });

  test('PostureIndex.empty não tem domínio mais fraco nem mais forte', () {
    final PostureIndex empty = PostureIndex.empty();
    expect(empty.weakestDomain, isNull);
    expect(empty.strongestDomain, isNull);
    expect(empty.overallScore, 0);
  });
}
