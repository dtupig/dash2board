import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/onboarding/presentation/onboarding_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget harness() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const OnboardingGate(
          role: UserRole.strategic,
          child: Scaffold(body: Center(child: Text('Painel do CISO'))),
        ),
      ),
    );
  }

  testWidgets('na primeira visita, mostra a introdução por cima do painel', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sua postura, de relance'), findsOneWidget);
    // O painel já está construído por baixo, só coberto pela introdução.
    expect(find.text('Painel do CISO'), findsOneWidget);
  });

  testWidgets('pular marca como visto e não aparece de novo', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Pular'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sua postura, de relance'), findsNothing);

    // Reabrindo o painel (nova árvore, mesmas shared_preferences) - a
    // introdução não deve reaparecer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sua postura, de relance'), findsNothing);
    expect(find.text('Painel do CISO'), findsOneWidget);
  });

  testWidgets('já visto anteriormente, não mostra a introdução', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_seen_strategic': true,
    });

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sua postura, de relance'), findsNothing);
    expect(find.text('Painel do CISO'), findsOneWidget);
  });
}
