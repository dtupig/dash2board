import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'briefing_data.dart';
import 'briefing_pdf_colors.dart';
import 'briefing_pdf_posture_section.dart';
import 'briefing_pdf_sections.dart';

/// Monta o PDF de uma página do briefing executivo a partir de
/// [BriefingData].
///
/// Desenhado direto com a API do pacote `pdf` (`pw.Widget`, `pw.CustomPaint`
/// com `PdfGraphics`) - deliberadamente SEM reaproveitar nenhum
/// `CustomPainter` de `lib/core/widgets/charts/`, que desenha em
/// `dart:ui Canvas`, uma API incompatível com a de geração de PDF.
///
/// As seções 2 a 5 vivem em `briefing_pdf_sections.dart` e as cores em
/// `briefing_pdf_colors.dart`, para manter este arquivo abaixo do limite de
/// 250 linhas.
abstract final class BriefingPdfBuilder {
  static Future<Uint8List> build(BriefingData data) async {
    final pw.Document document = pw.Document();
    final pw.Font base = pw.Font.helvetica();
    final pw.Font bold = pw.Font.helveticaBold();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        margin: const pw.EdgeInsets.fromLTRB(30, 28, 30, 24),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            _header(),
            pw.SizedBox(height: 14),
            buildPostureSection(data),
            pw.SizedBox(height: 12),
            buildWeakestDomainsSection(data),
            pw.SizedBox(height: 12),
            buildExposuresSection(data),
            pw.SizedBox(height: 12),
            buildComplianceSection(data),
            pw.SizedBox(height: 12),
            buildDecisionsSection(data),
            pw.Spacer(),
            _footer(data),
          ],
        ),
      ),
    );

    return document.save();
  }

  static pw.Widget _header() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        pw.CustomPaint(
          size: const PdfPoint(26, 26),
          painter: (PdfGraphics canvas, PdfPoint size) {
            _paintLogo(canvas, size);
          },
        ),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              'ELYTRON DASH2BOARD',
              style: const pw.TextStyle(
                fontSize: 9,
                color: BriefingPdfColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
            pw.Text(
              'Briefing executivo de segurança',
              style: const pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: BriefingPdfColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static void _paintLogo(PdfGraphics canvas, PdfPoint size) {
    final double cx = size.x / 2;
    final double cy = size.y / 2;
    final double r = size.x / 2;
    canvas
      ..setColor(BriefingPdfColors.accent)
      ..moveTo(cx, cy - r);
    for (int i = 1; i <= 6; i++) {
      final double angle = (math.pi / 3) * i - math.pi / 2;
      canvas.lineTo(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    canvas
      ..fillPath()
      ..setStrokeColor(BriefingPdfColors.accent)
      ..setLineWidth(1.2)
      ..moveTo(cx - r * 0.4, cy + r * 0.26)
      ..lineTo(cx - r * 0.08, cy - r * 0.10)
      ..lineTo(cx + r * 0.14, cy + r * 0.10)
      ..lineTo(cx + r * 0.46, cy - r * 0.34)
      ..strokePath();
  }

  static pw.Widget _footer(BriefingData data) {
    final DateTime g = data.generatedAt;
    final String date =
        '${g.day.toString().padLeft(2, '0')}/${g.month.toString().padLeft(2, '0')}/${g.year} '
        '${g.hour.toString().padLeft(2, '0')}:${g.minute.toString().padLeft(2, '0')}';
    final String source = data.isMockData
        ? 'Dados de demonstração (modo mock), tenant "${data.tenantId}".'
        : 'Cloud Firestore, tenant "${data.tenantId}", agregados '
            'pré-calculados por Cloud Functions.';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Divider(color: BriefingPdfColors.track, thickness: 1),
        pw.SizedBox(height: 4),
        pw.Text(
          'Gerado em $date · Fonte: $source',
          style: const pw.TextStyle(
              fontSize: 8, color: BriefingPdfColors.textMuted),
        ),
      ],
    );
  }
}
