import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fundo institucional da jornada de entrada (splash, boas-vindas, login).
///
/// Duas manchas de luz em movimento muito lento sobre a superfície escura.
/// A animação é sutil de propósito: transmite "sistema vivo / telemetria"
/// sem competir com o conteúdo nem cansar quem olha o painel o dia inteiro.
///
/// Respeita `MediaQuery.disableAnimations` (acessibilidade / economia de
/// bateria): nesse caso renderiza um gradiente estático.
class AuroraBackdrop extends StatefulWidget {
  const AuroraBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Reduzir movimento" precisa parar o ticker de verdade, não só trocar
    // o que é desenhado: um `AnimationController` girando em segundo plano
    // sem nada ouvindo ainda consome CPU e bateria à toa.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surface),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (reduceMotion)
            const _StaticAurora()
          else
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  painter: _AuroraPainter(progress: _controller.value),
                );
              },
            ),
          const _GridOverlay(),
          widget.child,
        ],
      ),
    );
  }
}

class _StaticAurora extends StatelessWidget {
  const _StaticAurora();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -0.8),
          radius: 1.2,
          colors: <Color>[
            Color(0x2600E08A),
            Color(0x00000000),
          ],
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress * 2 * math.pi;

    _blob(
      canvas,
      size,
      center: Offset(
        size.width * (0.22 + 0.10 * math.cos(t)),
        size.height * (0.16 + 0.06 * math.sin(t)),
      ),
      radius: size.width * 0.85,
      color: AppColors.brandGreen.withValues(alpha: 0.18),
    );

    _blob(
      canvas,
      size,
      center: Offset(
        size.width * (0.86 + 0.08 * math.sin(t * 0.7)),
        size.height * (0.72 + 0.07 * math.cos(t * 0.7)),
      ),
      radius: size.width * 0.75,
      color: AppColors.brandCyan.withValues(alpha: 0.13),
    );

    _blob(
      canvas,
      size,
      center: Offset(
        size.width * (0.10 + 0.05 * math.sin(t * 1.3)),
        size.height * (0.94 + 0.03 * math.cos(t * 1.3)),
      ),
      radius: size.width * 0.60,
      color: AppColors.brandViolet.withValues(alpha: 0.10),
    );
  }

  void _blob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Malha técnica discreta - referência visual a console de operação.
class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.035),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double step = 32;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.color != color;
}
