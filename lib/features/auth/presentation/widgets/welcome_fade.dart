import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Entrada escalonada (fade + leve deslocamento vertical) da `WelcomeScreen`.
/// Respeita "reduzir movimento". Isolado para manter aquele arquivo abaixo
/// do limite de 250 linhas.
class WelcomeFade extends StatelessWidget {
  const WelcomeFade({
    super.key,
    required this.controller,
    required this.start,
    required this.child,
  });

  final AnimationController controller;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final double end = math.min<double>(1, start + 0.45);
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? inner) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - animation.value)),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }
}
