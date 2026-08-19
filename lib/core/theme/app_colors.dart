import 'package:flutter/material.dart';

/// Paleta institucional do Elytron Dash2Board.
///
/// O produto é *dark-first* (padrão de ferramentas de SecOps / NOC / SOC),
/// com um tema claro equivalente para uso em reunião de Board e projeção.
///
/// REGRA DO PROJETO: nunca use `Color.withOpacity(...)` (deprecated).
/// Use sempre `Color.withValues(alpha: ...)`.
abstract final class AppColors {
  // ---------------------------------------------------------------------
  // Marca
  // ---------------------------------------------------------------------
  /// Verde Elytron - ação primária, estado saudável, acento da marca.
  static const Color brandGreen = Color(0xFF00E08A);
  static const Color brandGreenDim = Color(0xFF00B76F);

  /// Ciano de telemetria - dados, séries temporais, links.
  static const Color brandCyan = Color(0xFF21C7E8);

  /// Violeta executivo - camada de Board / risco de negócio.
  static const Color brandViolet = Color(0xFFA98BFF);

  // ---------------------------------------------------------------------
  // Superfícies - tema escuro
  // ---------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF070B12);
  static const Color darkSurface = Color(0xFF0E1622);
  static const Color darkSurfaceElevated = Color(0xFF16202E);
  static const Color darkSurfaceHighest = Color(0xFF1D2836);
  static const Color darkOutline = Color(0xFF24303F);
  static const Color darkTextPrimary = Color(0xFFE8EEF5);
  static const Color darkTextSecondary = Color(0xFF93A2B5);

  // ---------------------------------------------------------------------
  // Superfícies - tema claro
  // ---------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFEDF1F6);
  static const Color lightSurfaceHighest = Color(0xFFE2E8F0);
  static const Color lightOutline = Color(0xFFCBD5E1);
  static const Color lightTextPrimary = Color(0xFF0B1421);
  static const Color lightTextSecondary = Color(0xFF52627A);

  // ---------------------------------------------------------------------
  // Severidade (alinhado a CVSS v3.1 / v4.0)
  // ---------------------------------------------------------------------
  static const Color severityCritical = Color(0xFFFF4D5E);
  static const Color severityHigh = Color(0xFFFF8A3D);
  static const Color severityMedium = Color(0xFFFFC53D);
  static const Color severityLow = Color(0xFF21C7E8);
  static const Color severityInfo = Color(0xFF7C8CA1);

  // ---------------------------------------------------------------------
  // Semânticos
  // ---------------------------------------------------------------------
  static const Color success = brandGreen;
  static const Color warning = severityMedium;
  static const Color danger = severityCritical;

  /// Cor de acento de cada persona. Mantida aqui para que a identidade de
  /// cada painel seja consistente entre a tela de boas-vindas e o dashboard.
  static const Color personaOperational = brandCyan;
  static const Color personaStrategic = brandGreen;
  static const Color personaBoard = brandViolet;
}
