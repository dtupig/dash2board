import 'package:flutter/widgets.dart';

import '../../theme/app_spacing.dart';

/// Duração de revelação de um desenho de gráfico.
///
/// Zerada quando o usuário pediu movimento reduzido
/// (`MediaQuery.disableAnimationsOf`) - nunca "quase" respeita a preferência,
/// a animação simplesmente não acontece.
Duration chartRevealDuration(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : AppDuration.normal;
}

/// Revelação sutil (fade) para o conteúdo desenhado de um gráfico.
///
/// Usado em vez de animar o próprio `CustomPainter` (traçar a linha, crescer
/// a barra): mais simples, mais previsível em telas pequenas e igualmente
/// eficaz para o objetivo de "não aparecer com um solavanco".
class ChartReveal extends StatelessWidget {
  const ChartReveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: chartRevealDuration(context),
      curve: Curves.easeOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }
}
