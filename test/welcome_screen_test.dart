import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/presentation/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tela de boas-vindas tem animações contínuas (aurora), portanto NUNCA use
/// `pumpAndSettle` aqui: use `pump(Duration)`.
void main() {
  Widget harness() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const WelcomeScreen(),
      ),
    );
  }

  testWidgets('apresenta marca, proposta de valor e CTA único', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('ELYTRON'), findsOneWidget);
    expect(find.text('Dash2Board'), findsOneWidget);
    expect(
      find.text('A decisão de segurança\nem uma única tela.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Entrar com e-mail corporativo'),
        findsOneWidget);
  });

  testWidgets('mostra as três personas e troca o conteúdo ao selecionar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Operação'), findsOneWidget);
    expect(find.text('CISO'), findsOneWidget);
    expect(find.text('Board'), findsOneWidget);

    // CISO é a persona destacada por padrão.
    expect(find.text('Segurança Estratégica / CISO'), findsOneWidget);

    await tester.tap(find.text('Board'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Board & Executivos de Negócio'), findsOneWidget);
  });
}
