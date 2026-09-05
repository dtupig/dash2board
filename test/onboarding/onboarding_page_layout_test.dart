import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/onboarding/presentation/onboarding_content.dart';
import 'package:elytron_dash2board/features/onboarding/presentation/onboarding_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const OnboardingPageData page = OnboardingPageData(
    icon: Icons.trending_up_rounded,
    title: 'Sua postura, de relance',
    description: 'Um índice de segurança consolidado.',
  );

  Widget harness() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
        body: OnboardingPageLayout(page: page, accent: Colors.teal),
      ),
    );
  }

  void setLogicalSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('em largura large, selo e texto ficam lado a lado (Row)', (
    WidgetTester tester,
  ) async {
    setLogicalSize(tester, const Size(1400, 900));

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.ancestor(of: find.text(page.title), matching: find.byType(Row)),
      findsOneWidget,
    );
  });

  testWidgets('em largura compact, mantém a coluna empilhada de hoje', (
    WidgetTester tester,
  ) async {
    setLogicalSize(tester, const Size(390, 844));

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.ancestor(of: find.text(page.title), matching: find.byType(Row)),
      findsNothing,
    );
    expect(
      find.ancestor(of: find.text(page.title), matching: find.byType(Column)),
      findsWidgets,
    );
  });
}
