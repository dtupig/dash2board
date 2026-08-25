import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/services/data/mock_services_repository.dart';
import 'package:elytron_dash2board/features/services/data/services_providers.dart';
import 'package:elytron_dash2board/features/services/presentation/wizard/request_wizard_screen.dart';
import 'package:elytron_dash2board/features/services/domain/request_driver.dart';
import 'package:elytron_dash2board/features/services/domain/request_urgency.dart';
import 'package:elytron_dash2board/features/services/presentation/wizard/wizard_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const Duration settle = Duration(milliseconds: 500);

  AppUser userWithRole(UserRole role) => AppUser(
        uid: 'demo-${role.wireValue}',
        email: '${role.wireValue}@demo.elytron',
        role: role,
        tenantId: 'tenant-demo',
      );

  Widget harness({required UserRole role, String serviceKey = 'web_api'}) {
    return ProviderScope(
      overrides: [
        appUserProvider.overrideWith(
          (Ref ref) => Stream<AppUser?>.value(userWithRole(role)),
        ),
        servicesRepositoryProvider.overrideWith(
          (Ref ref) => MockServicesRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: RequestWizardScreen(serviceKey: serviceKey),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('não avança do passo 1 com campo vazio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(harness(role: UserRole.operational));
    await tester.pump(settle);

    await tester.tap(find.text('Avançar'));
    await tester.pump(settle);

    expect(find.text('Escolha um motivo.'), findsOneWidget);
    expect(find.text('Este campo é obrigatório.'), findsOneWidget);
    // Segue no passo 1: o campo de descrição continua visível.
    expect(find.text('Descreva em uma frase'), findsOneWidget);
  });

  testWidgets('voltar preserva o que já foi digitado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(harness(role: UserRole.operational));
    await tester.pump(settle);

    await tester.tap(find.text('Achado de auditoria'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Novo app antes do lançamento',
    );
    await tester.pump();
    await tester.tap(find.text('Avançar'));
    await tester.pump(settle);

    // Agora no passo 2 (escopo) - volta para o passo 1.
    await tester.tap(find.text('Voltar'));
    await tester.pump(settle);

    expect(find.text('Novo app antes do lançamento'), findsOneWidget);
  });

  testWidgets('selecionar crise mostra o aviso do plantão DFIR', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(harness(role: UserRole.operational));
    await tester.pump(settle);

    await tester.tap(find.text('Achado de auditoria'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Descrição do caso de uso',
    );
    await tester.pump();
    await tester.tap(find.text('Avançar'));
    await tester.pump(settle);

    await tester.enterText(
      find.byType(TextField).first,
      'app.empresa.com',
    );
    await tester.pump();
    await tester.tap(find.text('Avançar'));
    await tester.pump(settle);

    expect(find.text('Crise'), findsOneWidget);
    await tester.tap(find.text('Crise'));
    await tester.pump(settle);

    expect(find.textContaining('plantão DFIR'), findsOneWidget);
  });

  Future<void> seedCompleteDraft(String serviceKey) async {
    const WizardDraft base = WizardDraft(
      driver: RequestDriver.auditFinding,
      useCaseDescription: 'Descrição completa do caso de uso',
      scopeAssetsText: 'app.empresa.com',
      urgency: RequestUrgency.planned,
      justification: 'Justificativa de negócio completa e suficiente.',
    );
    // `desiredWindow` não é const (DateTime não tem construtor const) - por
    // isso entra via `copyWith` fora do literal `const WizardDraft(...)`.
    final WizardDraft complete =
        base.copyWith(desiredWindow: DateTime.utc(2027, 1, 10));
    SharedPreferences.setMockInitialValues(<String, Object>{
      'wizard_draft_$serviceKey': complete.toJson(),
    });
  }

  testWidgets('rótulo do botão final para operational pede aprovação do CISO',
      (WidgetTester tester) async {
    await seedCompleteDraft('web_api');
    await tester.pumpWidget(harness(role: UserRole.operational));
    await tester.pump(settle);
    for (int i = 0; i < 4; i++) {
      await tester.tap(find.text('Avançar'));
      await tester.pump(settle);
    }
    expect(find.text('Enviar para aprovação do CISO'), findsOneWidget);
  });

  testWidgets('rótulo do botão final para strategic envia direto à Elytron',
      (WidgetTester tester) async {
    await seedCompleteDraft('web_api');
    await tester.pumpWidget(harness(role: UserRole.strategic));
    await tester.pump(settle);
    for (int i = 0; i < 4; i++) {
      await tester.tap(find.text('Avançar'));
      await tester.pump(settle);
    }
    expect(find.text('Enviar para a Elytron'), findsOneWidget);
  });
}
