import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/core/theme/chart_tokens.dart';
import 'package:elytron_dash2board/core/widgets/charts/delta_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `DeltaBadge` não anima, mas seguimos o padrão do projeto e nunca usamos
/// `pumpAndSettle`: sempre `pump(Duration)`.
void main() {
  Widget harness(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('positivo: seta para cima, sinal de mais e semântica de alta', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(const DeltaBadge(value: 8, periodLabel: 'em 30 dias')),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    expect(find.text('+8 pontos'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(DeltaBadge)).label,
      'Subiu 8 pontos em 30 dias.',
    );

    final Icon icon =
        tester.widget<Icon>(find.byIcon(Icons.arrow_upward_rounded));
    expect(icon.color, ChartTokens.divergentPositive);

    handle.dispose();
  });

  testWidgets('negativo: seta para baixo e semântica de queda', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(const DeltaBadge(value: -5)));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    expect(find.text('−5 pontos'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(DeltaBadge)).label,
      'Caiu 5 pontos.',
    );

    final Icon icon =
        tester.widget<Icon>(find.byIcon(Icons.arrow_downward_rounded));
    expect(icon.color, ChartTokens.divergentNegative);

    handle.dispose();
  });

  testWidgets('zero: ícone neutro e semântica de estabilidade', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(const DeltaBadge(value: 0)));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(DeltaBadge)).label,
      'Estável.',
    );

    final Icon icon = tester.widget<Icon>(find.byIcon(Icons.remove_rounded));
    expect(icon.color, ChartTokens.divergentNeutral);

    handle.dispose();
  });
}
