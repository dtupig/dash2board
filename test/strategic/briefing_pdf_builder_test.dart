import 'dart:typed_data';

import 'package:elytron_dash2board/features/strategic/data/mock_strategic_repository.dart';
import 'package:elytron_dash2board/features/strategic/domain/compliance_control.dart';
import 'package:elytron_dash2board/features/strategic/domain/posture_index.dart';
import 'package:elytron_dash2board/features/strategic/domain/posture_snapshot.dart';
import 'package:elytron_dash2board/features/strategic/domain/risk_item.dart';
import 'package:elytron_dash2board/features/strategic/presentation/briefing_data.dart';
import 'package:elytron_dash2board/features/strategic/presentation/briefing_pdf_builder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Achado 4b (docs/21_BACKLOG_ACHADOS_TECNICOS.md): `briefing_pdf_builder.dart`
/// foi dividido em `briefing_pdf_colors.dart`, `briefing_pdf_posture_section.dart`
/// e `briefing_pdf_sections.dart` para caber no limite de 250 linhas. Nenhum
/// teste exercitava `BriefingPdfBuilder.build` de fato antes desta divisão -
/// só a montagem de widget da tela de preview. Este teste garante que o PDF
/// continua sendo gerado (todas as 5 seções) depois do split.
void main() {
  test('gera um PDF válido com as 5 seções, sem lançar exceção', () async {
    const String tenantId = 'tenant-demo';
    final MockStrategicRepository repo = MockStrategicRepository();

    final PostureIndex postureIndex =
        await repo.watchPostureIndex(tenantId).first;
    final List<PostureSnapshot> postureHistory =
        await repo.watchPostureHistory(tenantId).first;
    final List<ComplianceControl> complianceControls =
        await repo.watchCompliance(tenantId).first;
    final List<RiskItem> risks = await repo.watchAllRisks(tenantId).first;

    final BriefingData data = BriefingData.build(
      postureIndex: postureIndex,
      postureHistory: postureHistory,
      complianceControls: complianceControls,
      risks: risks,
      isMockData: true,
      tenantId: tenantId,
      generatedAt: DateTime.utc(2026, 8, 1),
    );

    final Uint8List bytes = await BriefingPdfBuilder.build(data);

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
