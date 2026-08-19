import 'package:flutter/material.dart';

/// Tokens de cor para gráficos do Elytron Dash2Board.
///
/// Estes valores foram **validados** para as duas superfícies do produto
/// (`AppColors.darkBackground`/`AppColors.lightBackground`) e para as três
/// funções de cor que um gráfico executivo precisa distinguir. Alterar
/// qualquer valor aqui exige revalidar contraste e distinguibilidade nos dois
/// temas antes de mesclar — não são "gosto", são o resultado de uma checagem.
///
/// ## As 10 regras que todo widget em `lib/core/widgets/charts/` obedece
///
/// 1. Cor por função: identidade → [categorical]; magnitude → [sequentialDark]
///    / [sequentialLight] (matiz única); polaridade → [divergentNegative] /
///    [divergentNeutral] / [divergentPositive]; estado → `AppColors.severity*`
///    (nunca redeclarado aqui - ver nota no fim deste arquivo).
/// 2. A ordem categórica é fixa e **nunca** ciclada. Uma 4ª série não existe:
///    vira "Outros" ou o dado é separado em gráficos pequenos.
/// 3. Nunca dois eixos Y. Duas medidas de escalas diferentes viram dois
///    gráficos ou são indexadas a uma base comum.
/// 4. A cor segue a **entidade**, não a posição na lista. Por isso os widgets
///    de múltiplas séries recebem a cor já resolvida por quem chama: filtrar
///    uma série não pode repintar as que sobraram.
/// 5. A partir de 2 séries a legenda é obrigatória, e a identidade nunca é só
///    cor: rótulo direto ou marcador com forma sempre acompanham a cor.
/// 6. Texto usa os tokens de texto do tema (`onSurface`/`onSurfaceVariant`),
///    nunca a cor da série/status. A cor fica no traço, no marcador ou no
///    ícone - nunca no texto do dado.
/// 7. Grade e eixos são recessivos: `outlineVariant` com alpha ≤ 0.5, 1px.
/// 8. Marcas finas: linha de 2px ([lineStrokeWidth]), ponto ≥ 8px
///    ([pointMinDiameter]), topo de barra arredondado em 4px
///    ([barEndRadius]) ancorado na linha de base, [stackedSegmentGap] de
///    folga entre segmentos empilhados.
/// 9. Rótulo direto é seletivo - nunca um número em cada ponto.
/// 10. O tema claro tem passos próprios ([sequentialLight]), escolhidos, e não
///     um espelho invertido do escuro.
abstract final class ChartTokens {
  // ---------------------------------------------------------------------
  // Categórica (identidade de série) - ordem FIXA, no máximo 3 séries.
  // ---------------------------------------------------------------------

  /// "Nossa organização" - teal.
  static const Color categoricalSlot1 = Color(0xFF0E9C8F);

  /// "Mediana do setor" - índigo.
  static const Color categoricalSlot2 = Color(0xFF7C79EE);

  /// "Meta" - âmbar.
  static const Color categoricalSlot3 = Color(0xFFC07A18);

  /// Os três slots, nesta ordem fixa. Nunca percorrer com `%` para uma 4ª
  /// série - ver regra 2.
  static const List<Color> categorical = <Color>[
    categoricalSlot1,
    categoricalSlot2,
    categoricalSlot3,
  ];

  // ---------------------------------------------------------------------
  // Sequencial (magnitude, matiz única) - do menor para o maior.
  // ---------------------------------------------------------------------

  static const List<Color> sequentialDark = <Color>[
    Color(0xFF0E7F75),
    Color(0xFF0E9C8F),
    Color(0xFF2FBBAD),
    Color(0xFF6ED6C9),
    Color(0xFFAEEDE4),
  ];

  static const List<Color> sequentialLight = <Color>[
    Color(0xFF5CC1B3),
    Color(0xFF2FAB9D),
    Color(0xFF0C8F83),
    Color(0xFF0A6E64),
    Color(0xFF064B44),
  ];

  /// Rampa sequencial correta para o [brightness] atual. O tema claro nunca
  /// deve usar o inverso do escuro - por isso duas listas próprias (regra 10).
  static List<Color> sequentialFor(Brightness brightness) {
    return brightness == Brightness.dark ? sequentialDark : sequentialLight;
  }

  // ---------------------------------------------------------------------
  // Divergente (variação: piorou ↔ melhorou).
  // ---------------------------------------------------------------------

  static const Color divergentNegative = Color(0xFFC07A18);
  static const Color divergentNeutral = Color(0xFF7C8CA1);
  static const Color divergentPositive = Color(0xFF0E9C8F);

  // ---------------------------------------------------------------------
  // Marcas e geometria (regra 8).
  // ---------------------------------------------------------------------

  static const double lineStrokeWidth = 2;
  static const double pointMinDiameter = 8;
  static const double barEndRadius = 4;
  static const double stackedSegmentGap = 2;

  /// Alpha máximo de grade/eixos (regra 7).
  static const double gridMaxAlpha = 0.5;

  /// Alpha da área sob a linha da série 1 nos gráficos de tendência.
  static const double areaFillAlpha = 0.12;
}

// -----------------------------------------------------------------------
// Nota sobre status/severidade (regra 1, "estado → status"):
//
// As cores de severidade (`AppColors.severityCritical/High/Medium/Low`) são
// REUSADAS, nunca redeclaradas aqui. Isso é deliberado: existe um único lugar
// no código onde "crítico é vermelho" é verdade, e é o mesmo lugar usado fora
// dos gráficos (chips, badges). Essas cores são RESERVADAS: nenhum widget
// deste diretório pode usá-las para pintar uma série categórica, sequencial
// ou divergente - só para representar estado/severidade.
// -----------------------------------------------------------------------
