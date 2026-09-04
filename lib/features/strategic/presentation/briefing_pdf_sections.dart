import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/compliance_control.dart';
import '../domain/risk_item.dart';
import '../domain/security_domain.dart';
import 'briefing_copy.dart';
import 'briefing_data.dart';
import 'briefing_formatting.dart';
import 'briefing_pdf_colors.dart';

/// Seções numeradas do PDF do briefing executivo (2 a 5 - a 1, índice de
/// postura, fica em `briefing_pdf_posture_section.dart` por ser a mais
/// longa). Isolado para manter os arquivos abaixo do limite de 250 linhas.
pw.Widget buildSectionTitle(String text) {
  return pw.Text(
    text,
    style: const pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      color: BriefingPdfColors.textDark,
      letterSpacing: 0.3,
    ),
  );
}

pw.Widget buildWeakestDomainsSection(BriefingData data) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      buildSectionTitle('2. Domínios que mais precisam de atenção'),
      pw.SizedBox(height: 6),
      for (final MapEntry<SecurityDomain, int> entry in data.weakestDomains)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.SizedBox(
                width: 112,
                child: pw.Text(
                  '${entry.key.label} (${entry.value} pts)',
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: BriefingPdfColors.textDark,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  entry.key.briefingConsequence,
                  style: const pw.TextStyle(
                      fontSize: 9.5, color: BriefingPdfColors.textDark),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

pw.Widget buildExposuresSection(BriefingData data) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      buildSectionTitle(
        '3. Maiores exposições financeiras (perda anual esperada, ou '
        'ALE - o quanto um risco custaria à empresa por ano, em média, '
        'se nada mudar)',
      ),
      pw.SizedBox(height: 6),
      for (final RiskItem risk in data.topExposures)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Text(
                  '${risk.title} (${risk.businessUnit})',
                  style: const pw.TextStyle(
                      fontSize: 9.5, color: BriefingPdfColors.textDark),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                formatCurrencyBrl(risk.annualLossExpectancy),
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: BriefingPdfColors.textDark,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

void _paintPercentBar(PdfGraphics canvas, PdfPoint size, int percent) {
  canvas
    ..setColor(BriefingPdfColors.track)
    ..drawRect(0, 0, size.x, size.y)
    ..fillPath();
  final double width = size.x * (percent / 100).clamp(0, 1);
  canvas
    ..setColor(BriefingPdfColors.accent)
    ..drawRect(0, 0, width, size.y)
    ..fillPath();
}

pw.Widget buildComplianceSection(BriefingData data) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      buildSectionTitle('4. Situação de compliance por framework'),
      pw.SizedBox(height: 6),
      for (final ComplianceFramework framework in ComplianceFramework.values)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: <pw.Widget>[
              pw.SizedBox(
                width: 240,
                child: pw.Text(
                  framework.briefingFullName,
                  style: const pw.TextStyle(
                      fontSize: 9, color: BriefingPdfColors.textDark),
                ),
              ),
              pw.Expanded(
                child: pw.CustomPaint(
                  size: const PdfPoint(200, 10),
                  painter: (PdfGraphics canvas, PdfPoint size) {
                    final int? percent =
                        data.compliancePercentByFramework[framework];
                    _paintPercentBar(canvas, size, percent ?? 0);
                  },
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 60,
                child: pw.Text(
                  data.compliancePercentByFramework[framework] == null
                      ? 'sem dados'
                      : '${data.compliancePercentByFramework[framework]}% conforme',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: BriefingPdfColors.textDark,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

pw.Widget buildDecisionsSection(BriefingData data) {
  const int maxShown = 4;
  final List<RiskItem> shown = data.pendingDecisions.take(maxShown).toList();
  final int hidden = data.pendingDecisions.length - shown.length;

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      buildSectionTitle('5. Decisões que dependem do comitê'),
      pw.SizedBox(height: 6),
      if (shown.isEmpty)
        pw.Text(
          'Nenhuma decisão de risco pendente no momento.',
          style: const pw.TextStyle(
              fontSize: 9.5, color: BriefingPdfColors.textDark),
        )
      else ...<pw.Widget>[
        for (final RiskItem risk in shown)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              // Hífen, não "•": a fonte Helvetica base-14 do PDF usa
              // WinAnsiEncoding e não tem o glifo do bullet Unicode (a
              // geração real do PDF confirmou isso - o caractere some
              // silenciosamente sem o aviso virar erro).
              '- ${risk.title} (${risk.businessUnit}) - tratamento '
              'proposto: ${risk.treatment.label}, exposição de '
              '${formatCurrencyBrl(risk.annualLossExpectancy)} por ano.',
              style: const pw.TextStyle(
                  fontSize: 9.5, color: BriefingPdfColors.textDark),
            ),
          ),
        if (hidden > 0)
          pw.Text(
            'e mais $hidden decisão${hidden == 1 ? '' : 'ões'} pendente'
            '${hidden == 1 ? '' : 's'} no painel de riscos.',
            style: const pw.TextStyle(
                fontSize: 9, color: BriefingPdfColors.textMuted),
          ),
      ],
    ],
  );
}
