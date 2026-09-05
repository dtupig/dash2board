import 'package:flutter/widgets.dart';

/// Faixas de largura da grade responsiva do Material 3 (premissa P-8 do
/// épico E-W, `docs/19_HISTORIAS_INTERFACE_WEB.md`).
///
/// Só decide "que faixa de largura é esta" - não decide navegação nem
/// layout. Cada tela usa [LayoutSize.of] e escolhe sua própria composição.
enum LayoutSize {
  /// `< 600` - celular em pé, navegação empilhada.
  compact,

  /// `600` a `839` - celular deitado ou tablet pequeno.
  medium,

  /// `840` a `1199` - tablet grande ou janela de navegador estreita.
  expanded,

  /// `>= 1200` - monitor ou navegador maximizado.
  large;

  static LayoutSize of(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) {
      return LayoutSize.large;
    }
    if (width >= 840) {
      return LayoutSize.expanded;
    }
    if (width >= 600) {
      return LayoutSize.medium;
    }
    return LayoutSize.compact;
  }
}
