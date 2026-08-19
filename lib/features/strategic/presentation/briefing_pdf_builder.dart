import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/compliance_control.dart';
import '../domain/risk_item.dart';
import '../domain/security_domain.dart';
import 'briefing_copy.dart';
import 'briefing_data.dart';
import 'briefing_formatting.dart';

/// Monta o PDF de uma página do briefing executivo a partir de
/// [BriefingData].
///
/// Desenhado direto com a API do pacote `pdf` (`pw.Widget`, `pw.CustomPaint`
/// com `PdfGraphics`) - deliberadamente SEM reaproveitar nenhum
/// `CustomPainter` de `lib/core/widgets/charts/`, que desenha em
/// `dart:ui Canvas`, uma API incompatível com a de geração de PDF.
abstract final class BriefingPdfBuilder {
  static const PdfColor _accent = PdfColor.fromInt(0xFF0E9C8F);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF0B1421);
  static const PdfColor _textMuted = PdfColor.fromInt(0xFF52627A);
  static const PdfColor _track = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _negative = PdfColor.fromInt(0xFFC07A18);

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
            _postureSection(data),
            pw.SizedBox(height: 12),
            _weakestDomainsSection(data),
            pw.SizedBox(height: 12),
            _exposuresSection(data),
            pw.SizedBox(height: 12),
            _complianceSection(data),
            pw.SizedBox(height: 12),
            _decisionsSection(data),
            pw.Spacer(),
            _footer(data),
          ],
        ),
      ),
    );

    return document.save();
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _textDark,
        letterSpacing: 0.3,
      ),
    );
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
                color: _textMuted,
                letterSpacing: 1.4,
              ),
            ),
            pw.Text(
              'Briefing executivo de segurança',
              style: const pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: _textDark,
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
      ..setColor(_accent)
      ..moveTo(cx, cy - r);
    for (int i = 1; i <= 6; i++) {
      final double angle = (math.pi / 3) * i - math.pi / 2;
      canvas.lineTo(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    canvas
      ..fillPath()
      ..setStrokeColor(_accent)
      ..setLineWidth(1.2)
      ..moveTo(cx - r * 0.4, cy + r * 0.26)
      ..lineTo(cx - r * 0.08, cy - r * 0.10)
      ..lineTo(cx + r * 0.14, cy + r * 0.10)
      ..lineTo(cx + r * 0.46, cy - r * 0.34)
      ..strokePath();
  }

  static pw.Widget _postureSection(BriefingData data) {
    final bool isPositive = data.delta > 0;
    final bool isNegative = data.delta < 0;
    // A cor de sentimento fica só no triângulo, nunca no texto (mesma regra
    // 6 de `chart_tokens.dart` que o resto do app segue): `#0E9C8F` sobre
    // fundo branco não tem contraste suficiente (3,4:1) para texto normal
    // de acordo com o WCAG AA (mínimo 4,5:1), mas passa como elemento
    // gráfico (mínimo 3:1).
    final PdfColor deltaTriangleColor =
        isPositive ? _accent : (isNegative ? _negative : _textMuted);
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
        _sectionTitle('1. Índice de postura de segurança'),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: <pw.Widget>[
            pw.Text(
              '${data.overallScore}',
              style: const pw.TextStyle(
                fontSize: 30,
                fontWeight: pw.FontWeight.bold,
                color: _textDark,
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Text(
              'de 100',
              style: const pw.TextStyle(fontSize: 10, color: _textMuted),
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
              style: const pw.TextStyle(fontSize: 10, color: _textDark),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'O índice de postura resume, em uma nota de 0 a 100, o quanto os '
          'controles de segurança da empresa estão implementados e '
          'eficazes. A empresa está $peerComparisonText.',
          style: const pw.TextStyle(fontSize: 9.5, color: _textDark),
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

  static void _paintComparisonBar(
    PdfGraphics canvas,
    PdfPoint size, {
    required double organizationValue,
    required double peerValue,
    required double maxValue,
  }) {
    canvas
      ..setColor(_track)
      ..drawRect(0, 0, size.x, size.y)
      ..fillPath();

    final double orgWidth = size.x * (organizationValue / maxValue).clamp(0, 1);
    canvas
      ..setColor(_accent)
      ..drawRect(0, 0, orgWidth, size.y)
      ..fillPath();

    final double peerX = size.x * (peerValue / maxValue).clamp(0, 1);
    canvas
      ..setStrokeColor(_textDark)
      ..setLineWidth(1.4)
      ..drawLine(peerX, -2, peerX, size.y + 2)
      ..strokePath();
  }

  /// Triângulo de tendência (para cima/para baixo) - carrega a cor de
  /// sentimento como elemento gráfico, nunca como cor de texto.
  static void _paintTrend(
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

  static pw.Widget _weakestDomainsSection(BriefingData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('2. Domínios que mais precisam de atenção'),
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
                      color: _textDark,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    entry.key.briefingConsequence,
                    style: const pw.TextStyle(fontSize: 9.5, color: _textDark),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _exposuresSection(BriefingData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle(
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
                    style: const pw.TextStyle(fontSize: 9.5, color: _textDark),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  formatCurrencyBrl(risk.annualLossExpectancy),
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _complianceSection(BriefingData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('4. Situação de compliance por framework'),
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
                    style: const pw.TextStyle(fontSize: 9, color: _textDark),
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
                      color: _textDark,
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

  static void _paintPercentBar(PdfGraphics canvas, PdfPoint size, int percent) {
    canvas
      ..setColor(_track)
      ..drawRect(0, 0, size.x, size.y)
      ..fillPath();
    final double width = size.x * (percent / 100).clamp(0, 1);
    canvas
      ..setColor(_accent)
      ..drawRect(0, 0, width, size.y)
      ..fillPath();
  }

  static pw.Widget _decisionsSection(BriefingData data) {
    const int maxShown = 4;
    final List<RiskItem> shown = data.pendingDecisions.take(maxShown).toList();
    final int hidden = data.pendingDecisions.length - shown.length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('5. Decisões que dependem do comitê'),
        pw.SizedBox(height: 6),
        if (shown.isEmpty)
          pw.Text(
            'Nenhuma decisão de risco pendente no momento.',
            style: const pw.TextStyle(fontSize: 9.5, color: _textDark),
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
                style: const pw.TextStyle(fontSize: 9.5, color: _textDark),
              ),
            ),
          if (hidden > 0)
            pw.Text(
              'e mais $hidden decisão${hidden == 1 ? '' : 'ões'} pendente'
              '${hidden == 1 ? '' : 's'} no painel de riscos.',
              style: const pw.TextStyle(fontSize: 9, color: _textMuted),
            ),
        ],
      ],
    );
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
        pw.Divider(color: _track, thickness: 1),
        pw.SizedBox(height: 4),
        pw.Text(
          'Gerado em $date · Fonte: $source',
          style: const pw.TextStyle(fontSize: 8, color: _textMuted),
        ),
      ],
    );
  }
}
