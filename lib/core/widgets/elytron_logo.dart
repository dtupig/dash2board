import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Marca do Elytron Dash2Board desenhada em código (sem dependência de asset).
///
/// Forma: escudo hexagonal (proteção) com um vetor ascendente interno
/// (tendência / inteligência). Usa gradiente verde -> ciano da marca.
class ElytronLogo extends StatelessWidget {
  const ElytronLogo({
    super.key,
    this.size = 72,
    this.showGlow = true,
  });

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ElytronLogoPainter(showGlow: showGlow),
        isComplex: true,
      ),
    );
  }
}

class _ElytronLogoPainter extends CustomPainter {
  const _ElytronLogoPainter({required this.showGlow});

  final bool showGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    final Path hexagon = _hexagonPath(center, radius * 0.94);

    if (showGlow) {
      final Paint glow = Paint()
        ..color = AppColors.brandGreen.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.34);
      canvas.drawPath(hexagon, glow);
    }

    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          AppColors.brandGreen.withValues(alpha: 0.16),
          AppColors.brandCyan.withValues(alpha: 0.06),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(hexagon, fill);

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, size.width * 0.028)
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[AppColors.brandGreen, AppColors.brandCyan],
      ).createShader(Offset.zero & size);
    canvas.drawPath(hexagon, stroke);

    // Vetor ascendente interno: leitura de "tendência sob proteção".
    final Path trend = Path()
      ..moveTo(center.dx - radius * 0.40, center.dy + radius * 0.26)
      ..lineTo(center.dx - radius * 0.08, center.dy - radius * 0.10)
      ..lineTo(center.dx + radius * 0.14, center.dy + radius * 0.10)
      ..lineTo(center.dx + radius * 0.46, center.dy - radius * 0.34);

    final Paint trendPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, size.width * 0.048)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.brandGreen;
    canvas.drawPath(trend, trendPaint);

    final Paint dot = Paint()..color = AppColors.brandCyan;
    canvas.drawCircle(
      Offset(center.dx + radius * 0.46, center.dy - radius * 0.34),
      math.max(2, size.width * 0.038),
      dot,
    );
  }

  Path _hexagonPath(Offset center, double radius) {
    final Path path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (math.pi / 3) * i - math.pi / 2;
      final Offset point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_ElytronLogoPainter oldDelegate) =>
      oldDelegate.showGlow != showGlow;
}

/// Assinatura textual da marca, usada abaixo do símbolo.
class ElytronWordmark extends StatelessWidget {
  const ElytronWordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'ELYTRON',
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Dash2Board',
          style: (compact
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.headlineMedium)
              ?.copyWith(
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}
