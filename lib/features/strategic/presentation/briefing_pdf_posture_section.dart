import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'briefing_data.dart';
import 'briefing_pdf_colors.dart';
import 'briefing_pdf_sections.dart';

/// Seção 1 (índice de postura) do PDF do briefing executivo - a mais longa,
/// por isso separada das demais em `briefing_pdf_sections.dart`. Isolado
/// para manter os dois arquivos abaixo do limite de 250 linhas.
pw.Widget buildPostureSection(BriefingData data) {
  final bool isPositive = data.delta > 0;
  final bool isNegative = data.delta < 0;
  // A cor de sentimento fica só no triângulo, nunca no texto (mesma regra
  // 6 de `chart_tokens.dart` que o resto do app segue): `#0E9C8F` sobre
  // fundo branco não tem contraste suficiente (3,4:1) para texto normal de
  // acordo com o WCAG AA (mínimo 4,5:1), mas passa como elemento gráfico
  // (mínimo 3:1).
  final PdfColor deltaTriangleColor = isPositive
      ? BriefingPdfColors.accent
      : (isNegative ? BriefingPdfColors.negative : BriefingPdfColors.textMuted);
  final String deltaText =
      isPositive ? '+${data.delta}' : (isNegative ? '${data.delta}' : '0');
  final String peerComparisonText = data.overallScore >= data.peerMedian
      ? 'acima da mediana do setor (empresas do mesmo porte e segmento), '
          'que está em ${data.peerMedian} pontos'
      : 'abaixo da mediana do setor (empresas do mesmo porte e segmento), '
          'que está em ${data.peerMedian} pontos';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      buildSectionTitle('1. Índice de postura de segurança'),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: <pw.Widget>[
          pw.Text(
            '${data.overallScore}',
            style: const pw.TextStyle(
              fontSize: 30,
              fontWeight: pw.FontWeight.bold,
              color: BriefingPdfColors.textDark,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            'de 100',
            style: const pw.TextStyle(
                fontSize: 10, color: BriefingPdfColors.textMuted),
          ),
          pw.SizedBox(width: 12),
          if (isPositive || isNegative) ...<pw.Widget>[
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 1.5, right: 3),
              child: pw.CustomPaint(
                size: const PdfPoint(7, 7),
                painter: (PdfGraphics canvas, PdfPoint size) {
                  _paintTrend(canvas, size,
                      up: isPositive, color: deltaTriangleColor);
                },
              ),
            ),
          ],
          pw.Text(
            '$deltaText pontos nos últimos 12 meses',
            style: const pw.TextStyle(
                fontSize: 10, color: BriefingPdfColors.textDark),
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'O índice de postura resume, em uma nota de 0 a 100, o quanto os '
        'controles de segurança da empresa estão implementados e '
        'eficazes. A empresa está $peerComparisonText.',
        style: const pw.TextStyle(
            fontSize: 9.5, color: BriefingPdfColors.textDark),
      ),
      pw.SizedBox(height: 6),
      pw.CustomPaint(
        size: const PdfPoint(535, 14),
        painter: (PdfGraphics canvas, PdfPoint size) {
          _paintComparisonBar(
            canvas,
            size,
            organizationValue: data.overallScore.toDouble(),
            peerValue: data.peerMedian.toDouble(),
            maxValue: 100,
          );
        },
      ),
    ],
  );
}

void _paintComparisonBar(
  PdfGraphics canvas,
  PdfPoint size, {
  required double organizationValue,
  required double peerValue,
  required double maxValue,
}) {
  canvas
    ..setColor(BriefingPdfColors.track)
    ..drawRect(0, 0, size.x, size.y)
    ..fillPath();

  final double orgWidth = size.x * (organizationValue / maxValue).clamp(0, 1);
  canvas
    ..setColor(BriefingPdfColors.accent)
    ..drawRect(0, 0, orgWidth, size.y)
    ..fillPath();

  final double peerX = size.x * (peerValue / maxValue).clamp(0, 1);
  canvas
    ..setStrokeColor(BriefingPdfColors.textDark)
    ..setLineWidth(1.4)
    ..drawLine(peerX, -2, peerX, size.y + 2)
    ..strokePath();
}

/// Triângulo de tendência (para cima/para baixo) - carrega a cor de
/// sentimento como elemento gráfico, nunca como cor de texto.
void _paintTrend(
  PdfGraphics canvas,
  PdfPoint size, {
  required bool up,
  required PdfColor color,
}) {
  canvas.setColor(color);
  if (up) {
    canvas
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y);
  } else {
    canvas
      ..moveTo(0, 0)
      ..lineTo(size.x, 0)
      ..lineTo(size.x / 2, size.y);
  }
  canvas.fillPath();
}
