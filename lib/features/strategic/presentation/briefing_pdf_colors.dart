import 'package:pdf/pdf.dart';

/// Paleta do PDF do briefing executivo, compartilhada por
/// `briefing_pdf_builder.dart` e `briefing_pdf_sections.dart`.
abstract final class BriefingPdfColors {
  static const PdfColor accent = PdfColor.fromInt(0xFF0E9C8F);
  static const PdfColor textDark = PdfColor.fromInt(0xFF0B1421);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF52627A);
  static const PdfColor track = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor negative = PdfColor.fromInt(0xFFC07A18);
}
