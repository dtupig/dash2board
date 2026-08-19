import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/core/widgets/charts/chart_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `ChartLoading` tem uma animação contínua de brilho: nunca `pumpAndSettle`
/// aqui, sempre `pump(Duration)`.
void main() {
  Widget harness(Widget child) {
    return MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child));
  }

  testWidgets('ChartFrame renderiza título, subtítulo e o conteúdo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const ChartFrame(
          title: 'Índice de postura',
          subtitle: 'Últimos 12 meses',
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Índice de postura'), findsOneWidget);
    expect(find.text('Últimos 12 meses'), findsOneWidget);
  });

  testWidgets('ChartFrame mostra "Ver dados" só quando onShowTable é dado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      harness(
        ChartFrame(
          title: 'Compliance',
          onShowTable: (BuildContext context) => const Text('Tabela'),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ver dados'), findsOneWidget);

    await tester.tap(find.text('Ver dados'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tabela'), findsOneWidget);
  });

  testWidgets('estado ChartLoading renderiza sem lançar exceção', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(harness(const ChartLoading()));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(ChartLoading), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estado ChartEmpty renderiza mensagem e ação', (
    WidgetTester tester,
  ) async {
    bool tapped = false;
    await tester.pumpWidget(
      harness(
        ChartEmpty(
          message: 'Nenhum controle cadastrado ainda.',
          actionLabel: 'Cadastrar controle',
          onAction: () => tapped = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Nenhum controle cadastrado ainda.'), findsOneWidget);
    await tester.tap(find.text('Cadastrar controle'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tapped, isTrue);
  });

  testWidgets('estado ChartError renderiza mensagem segura e tentar de novo', (
    WidgetTester tester,
  ) async {
    bool retried = false;
    await tester.pumpWidget(
      harness(
        ChartError(
          message: 'Não foi possível carregar os dados agora.',
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('Não foi possível carregar os dados agora.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tentar de novo'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(retried, isTrue);
  });
}
