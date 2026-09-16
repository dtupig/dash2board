import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Escala tipográfica do Dash2Board.
///
/// Densa e sóbria: executivos leem números e títulos curtos; o time técnico
/// lê listas longas. Por isso a escala é levemente comprimida em relação ao
/// Material 3 padrão e usa `height` explícito para ritmo vertical previsível.
///
/// Três famílias, cada uma com um papel (mesmo mapeamento do mockup web da
/// Fase 1 do épico E-W, `Dash2Board Web.dc.html`):
/// - **Archivo** (`display*`/`headline*`/`title*`) - títulos e números
///   grandes, geométrica e com peso.
/// - **IBM Plex Sans** (`body*`) - texto corrido.
/// - **IBM Plex Mono** (`label*`) - rótulos "eyebrow", tags de severidade,
///   timestamps - já era o papel de `labelSmall`/`labelMedium` antes desta
///   mudança (maiúsculo, `letterSpacing` largo); só a fonte é nova.
abstract final class AppTypography {
  static TextTheme scale(Color primary, Color secondary) {
    TextStyle display(TextStyle style) => GoogleFonts.archivo(textStyle: style);
    TextStyle body(TextStyle style) =>
        GoogleFonts.ibmPlexSans(textStyle: style);
    TextStyle label(TextStyle style) =>
        GoogleFonts.ibmPlexMono(textStyle: style);

    return TextTheme(
      displayLarge: display(TextStyle(
        fontSize: 40,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: primary,
      )),
      displayMedium: display(TextStyle(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: primary,
      )),
      displaySmall: display(TextStyle(
        fontSize: 28,
        height: 1.18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: primary,
      )),
      headlineLarge: display(TextStyle(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: primary,
      )),
      headlineMedium: display(TextStyle(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: primary,
      )),
      headlineSmall: display(TextStyle(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: primary,
      )),
      titleLarge: display(TextStyle(
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: primary,
      )),
      titleMedium: display(TextStyle(
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: primary,
      )),
      titleSmall: display(TextStyle(
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: secondary,
      )),
      bodyLarge: body(TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: primary,
      )),
      bodyMedium: body(TextStyle(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: secondary,
      )),
      bodySmall: body(TextStyle(
        fontSize: 12.5,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: secondary,
      )),
      labelLarge: label(TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: primary,
      )),
      labelMedium: label(TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: secondary,
      )),
      labelSmall: label(TextStyle(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: secondary,
      )),
    );
  }
}
