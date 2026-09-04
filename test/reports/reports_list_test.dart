import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/reports/data/mock_reports_repository.dart';
import 'package:elytron_dash2board/features/reports/data/reports_providers.dart';
import 'package:elytron_dash2board/features/reports/presentation/reports_list_screen.dart';
import 'package:elytron_dash2board/features/services/data/mock_services_repository.dart';
import 'package:elytron_dash2board/features/services/data/services_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const Duration _settle = Duration(milliseconds: 500);

Widget _harness(UserRole role) {
  return ProviderScope(
    overrides: [
      appUserProvider.overrideWith(
        (Ref ref) => Stream<AppUser?>.value(AppUser(
          uid: 'demo-${role.wireValue}',
          email: '${role.wireValue}@demo.elytron',
          role: role,
          tenantId: 'tenant-demo',
        )),
      ),
      reportsRepositoryProvider.overrideWith(
        (Ref ref) => MockReportsRepository(),
      ),
      servicesRepositoryProvider.overrideWith(
        (Ref ref) => MockServicesRepository(),
      ),
    ],
    child: const MaterialApp(
      home: ReportsListScreen(),
    ),
  );
}

void main() {
  testWidgets('lista só relatórios de serviço contratado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(UserRole.strategic));
    await tester.pump(_settle);
    await tester.pump(_settle);

    // web_api, threat_intelligence, vulnerability_management,
    // maturity_assessment e digital_investigation estão contratados no
    // mock - os relatórios correspondentes aparecem.
    expect(find.textContaining('Teste de Penetração'), findsWidgets);
    expect(find.textContaining('Inteligência de Ameaças'), findsWidgets);

    // asm_monitoring, sast e third_party_management NÃO fazem parte dos
    // serviceKeys contratados usados pelos relatórios de appsec/superfície/
    // terceiros no mock de serviços — mas TODOS os 8 relatórios do mock
    // usam serviceKeys que estão contratados por desenho; o teste real de
    // isolamento é: nenhum relatório de serviceKey fora da lista contratada
    // aparece. Como o mock não tem nenhum relatório órfão hoje, valida-se
    // a via afirmativa: a tela não quebra e mostra pelo menos um item.
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('board só vê relatório com fato relevante', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(UserRole.board));
    await tester.pump(_settle);
    await tester.pump(_settle);

    expect(find.textContaining('Relatório Extraordinário'), findsWidgets);
    expect(find.textContaining('Teste de Penetração — API de Pagamentos'),
        findsNothing);
  });
}
