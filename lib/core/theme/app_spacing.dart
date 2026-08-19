import 'package:flutter/widgets.dart';

/// Escala de espaçamento em base 4, usada por todo o app.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;

  /// Margem horizontal padrão do conteúdo em telas de celular.
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: xl, vertical: xl);

  /// Largura máxima do conteúdo em tablets/desktop, para não esticar texto.
  static const double maxContentWidth = 520;
}

/// Raios de canto padronizados.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(md));
}

/// Durações de animação padronizadas.
abstract final class AppDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration splash = Duration(milliseconds: 900);
}
