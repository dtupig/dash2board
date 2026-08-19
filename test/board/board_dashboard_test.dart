import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/dashboard/presentation/board_dashboard_screen.dart';
import 'package:elytron_dash2board/features/strategic/data/mock_strategic_repository.dart';
import 'package:elytron_dash2board/features/strategic/data/strategic_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lista de termos técnicos que NUNCA podem aparecer no painel do board -
/// regra do prompt 9 ("zero jargão. Se o board quiser detalhe, ele chama o
/// CISO"). `ChartLoading`/`ChartFrame` animam: nunca `pumpAndSettle` aqui.
const List<String> _bannedJargon = <String>[
  'índice de postura',
  'postura',
  'controle',
  'cvss',
  'epss',
  'mitre',
  'cve',
  'siem',
  'iso 27001',
  'nist',
  'lgpd',
  'pci dss',
  'incidente',
  'framework',
  'domínio de segurança',
  'compliance',
];

void main() {
  const AppUser testUser = AppUser(
    uid: 'board-demo',
    email: 'board@demo.elytron',
    role: UserRole.board,
    tenantId: 'tenant-demo',
  );

  Widget harness() {
    return ProviderScope(
      overrides: [
        appUserProvider.overrideWith(
          (Ref ref) => Stream<AppUser?>.value(testUser),
        ),
        strategicRepositoryProvider.overrideWith(
          (Ref ref) => MockStrategicRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const BoardDashboardScreen(),
      ),
    );
  }

  const Duration loadDelay = Duration(milliseconds: 500);

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Concatena todo texto visível na árvore (`Text` e `RichText`), em
  /// minúsculas, para varrer por jargão proibido.
  String allVisibleText(WidgetTester tester) {
    final StringBuffer buffer = StringBuffer();
    for (final Element element in tester.elementList(find.byType(Text))) {
      final Text widget = element.widget as Text;
      if (widget.data != null) {
        buffer.writeln(widget.data);
      }
    }
    for (final Element element in tester.elementList(find.byType(RichText))) {
      final RichText widget = element.widget as RichText;
      buffer.writeln(widget.text.toPlainText());
    }
    return buffer.toString().toLowerCase();
  }

  testWidgets('exibe a soma de ALE dos riscos do mock', (WidgetTester tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(loadDelay);

    // Soma dos 6 riscos do mock: 4.200.000 + 1.800.000 + 2.600.000 + 950.000
    // + 3.100.000 + 180.000 = 12.830.000.
    expect(find.textContaining('R\$ 12.830.000'), findsOneWidget);
  });

  testWidgets('agrupa por unidade de negócio, ordenado por exposição', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(loadDelay);

    // Varejo (6,0 mi) > Indústria (3,55 mi) > Serviços Financeiros (3,1 mi)
    // > Corporativo (0,18 mi) - `DomainBarChart` ordena por valor
    // decrescente, independente da ordem de entrada.
    final Finder bars = find.byType(Text);
    final List<String> labelsInOrder = <String>[];
    for (final Element element in tester.elementList(bars)) {
      final Text widget = element.widget as Text;
      if (widget.data != null &&
          <String>['Varejo', 'Indústria', 'Serviços Financeiros', 'Corporativo']
              .contains(widget.data)) {
        labelsInOrder.add(widget.data!);
      }
    }
    expect(
      labelsInOrder,
      <String>['Varejo', 'Indústria', 'Serviços Financeiros', 'Corporativo'],
    );
  });

  testWidgets('não renderiza nenhum termo da lista de jargão proibido', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(loadDelay);

    final String allText = allVisibleText(tester);
    for (final String term in _bannedJargon) {
      expect(
        allText.contains(term),
        isFalse,
        reason: 'Termo proibido encontrado na tela do board: "$term"',
      );
    }
  });

  testWidgets('confirmar aceite sem nota é bloqueado', (WidgetTester tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(loadDelay);

    final Finder acceptButton = find.widgetWithText(FilledButton, 'Aceitar o risco').first;
    await tester.ensureVisible(acceptButton);
    await tester.pump();
    await tester.tap(acceptButton);
    await tester.pump(const Duration(milliseconds: 300));

    final FilledButton confirmButton =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar'));
    expect(confirmButton.onPressed, isNull);
  });
}
