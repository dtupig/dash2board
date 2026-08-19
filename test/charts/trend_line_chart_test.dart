import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/core/theme/chart_tokens.dart';
import 'package:elytron_dash2board/core/widgets/charts/trend_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O gráfico de tendência não tem animação contínua (só uma revelação de
/// entrada), mas seguimos o padrão do projeto: nunca `pumpAndSettle`.
void main() {
  final List<DateTime> timestamps = <DateTime>[
    DateTime.utc(2026, 1, 1),
    DateTime.utc(2026, 2, 1),
    DateTime.utc(2026, 3, 1),
  ];

  List<TrendSeries> seriesOfLength(int count) {
    return List<TrendSeries>.generate(
      count,
      (int i) => TrendSeries(
        label: 'Série ${i + 1}',
        values: <double>[64, 68, 72],
        color: ChartTokens.categorical[i % ChartTokens.categorical.length],
      ),
    );
  }

  Widget harness(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SizedBox(height: 240, width: 360, child: child),
      ),
    );
  }

  testWidgets('renderiza com 1 série', (WidgetTester tester) async {
    await tester.pumpWidget(
      harness(
        TrendLineChart(timestamps: timestamps, series: seriesOfLength(1)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TrendLineChart), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('renderiza com 2 séries e mostra a legenda', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      harness(
        TrendLineChart(timestamps: timestamps, series: seriesOfLength(2)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Série 1'), findsOneWidget);
    expect(find.text('Série 2'), findsOneWidget);
  });

  testWidgets('renderiza com 3 séries', (WidgetTester tester) async {
    await tester.pumpWidget(
      harness(
        TrendLineChart(timestamps: timestamps, series: seriesOfLength(3)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Série 1'), findsOneWidget);
    expect(find.text('Série 2'), findsOneWidget);
    expect(find.text('Série 3'), findsOneWidget);
  });

  test('com 4 séries lança AssertionError - regra dura, não sugestão', () {
    expect(
      () => TrendLineChart(timestamps: timestamps, series: seriesOfLength(4)),
      throwsAssertionError,
    );
  });

  testWidgets('toque em um ponto abre o tooltip com data e valores', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      harness(
        TrendLineChart(timestamps: timestamps, series: seriesOfLength(2)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tapAt(tester.getCenter(find.byType(TrendLineChart)));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('fev/26'), findsOneWidget);
  });
}
