import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/reports/data/mock_reports_repository.dart';
import 'package:elytron_dash2board/features/reports/data/reports_providers.dart';
import 'package:elytron_dash2board/features/reports/presentation/report_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const Duration _settle = Duration(milliseconds: 500);

const List<String> _forbiddenOnBoard = <String>[
  'CVE',
  'CVSS',
  'payload',
  'exploit',
  'hash',
  'IOC',
  'CWE',
];

AppUser _user(UserRole role) => AppUser(
      uid: 'demo-${role.wireValue}',
      email: '${role.wireValue}@demo.elytron',
      role: role,
      tenantId: 'tenant-demo',
    );

Widget _harness({required UserRole role, required String reportId}) {
  return ProviderScope(
    overrides: [
      appUserProvider.overrideWith(
        (Ref ref) => Stream<AppUser?>.value(_user(role)),
      ),
      reportsRepositoryProvider.overrideWith(
        (Ref ref) => MockReportsRepository(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: ReportViewerScreen(reportId: reportId),
    ),
  );
}

Iterable<String> _allTexts(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((Text t) => t.data ?? '');

void main() {
  const String interimReportId = 'rep-pentest-002-interim';
  const String secretReportId = 'rep-incident-001';

  testWidgets(
      'board abre relatório com fato relevante e não vê nenhum termo '
      'técnico proibido', (WidgetTester tester) async {
    await tester.pumpWidget(
      _harness(role: UserRole.board, reportId: interimReportId),
    );
    await tester.pump(_settle);
    await tester.pump(_settle);

    final String allText = _allTexts(tester).join(' ').toLowerCase();
    for (final String term in _forbiddenOnBoard) {
      expect(
        allText.contains(term.toLowerCase()),
        isFalse,
        reason: 'Termo proibido "$term" apareceu na visão board.',
      );
    }
    // A visão board mostra o fato relevante em linguagem de negócio.
    expect(find.textContaining('Decisão do board'), findsWidgets);
  });

  testWidgets('board NÃO abre relatório confidential sem fato relevante', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _harness(role: UserRole.board, reportId: 'rep-pentest-001'),
    );
    await tester.pump(_settle);
    await tester.pump(_settle);

    expect(
      find.textContaining('Solicitações são abertas'),
      findsNothing,
    );
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets(
      'operational NÃO vê seção de dado pessoal - aparece suprimida com '
      'aviso, nunca some em silêncio', (WidgetTester tester) async {
    await tester.pumpWidget(
      _harness(role: UserRole.operational, reportId: secretReportId),
    );
    await tester.pump(_settle);
    await tester.pump(_settle);

    // secret nunca abre para operational - a tela mostra o motivo, não uma
    // lista vazia.
    expect(find.textContaining('classificação diferente da sua'), findsWidgets);
  });

  testWidgets(
      'strategic registra leitura antes de renderizar relatório '
      'secret', (WidgetTester tester) async {
    await tester.pumpWidget(
      _harness(role: UserRole.strategic, reportId: secretReportId),
    );
    await tester.pump(_settle);
    await tester.pump(_settle);

    expect(find.text('Continuar e registrar leitura'), findsOneWidget);
    expect(
        find.text('Investigação de Fraude Financeira Interna'), findsNothing);

    await tester.tap(find.text('Continuar e registrar leitura'));
    await tester.pump(_settle);
    await tester.pump(_settle);

    expect(
        find.textContaining('Investigação de Fraude Financeira'), findsWidgets);
  });
}
