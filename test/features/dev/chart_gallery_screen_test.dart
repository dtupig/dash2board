import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/dev/chart_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A galeria embute widgets com revelação de entrada e um esqueleto de
/// carregamento com brilho contínuo: nunca `pumpAndSettle` aqui.
void main() {
  Widget harness(ThemeData theme) {
    return ProviderScope(
      child: MaterialApp(theme: theme, home: const ChartGalleryScreen()),
    );
  }

  /// A galeria é mais alta que a viewport padrão de teste (800x600): sem
  /// isso, as seções do fim da lista nunca são construídas e `find.text`
  /// não as encontra - não é um bug do widget, é o viewport do teste.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('renderiza todos os widgets de gráfico sem exceção no tema escuro', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness(AppTheme.dark));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('KpiTile'), findsOneWidget);
    expect(find.text('TrendLineChart · 3 séries'), findsOneWidget);
    expect(find.text('DomainBarChart'), findsOneWidget);
    expect(find.text('StackedStatusBar'), findsOneWidget);
    expect(find.text('ChartFrame · estados'), findsOneWidget);
  });

  testWidgets('renderiza todos os widgets de gráfico sem exceção no tema claro', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness(AppTheme.light));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('SeverityChip'), findsOneWidget);
    expect(find.text('Sparkline'), findsOneWidget);
  });

  testWidgets('o botão de tema alterna entre claro e escuro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(harness(AppTheme.dark));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });
}
