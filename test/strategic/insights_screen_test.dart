import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/strategic/data/mock_strategic_repository.dart';
import 'package:elytron_dash2board/features/strategic/data/strategic_providers.dart';
import 'package:elytron_dash2board/features/strategic/presentation/insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Igual à convenção de `compliance_screen_test.dart`: `ChartFrame`/
/// `ChartLoading` animam, nunca `pumpAndSettle` aqui.
void main() {
  const AppUser testUser = AppUser(
    uid: 'ciso-demo',
    email: 'ciso@demo.elytron',
    role: UserRole.strategic,
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
        home: const InsightsScreen(),
      ),
    );
  }

  const Duration loadDelay = Duration(milliseconds: 500);

  /// A tela é mais alta que a viewport padrão de teste (800x600) - sem
  /// isso, itens no fim do feed nunca ficam visíveis para `find`/`tap`.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('agrupa os insights por mês', (WidgetTester tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(loadDelay);

    expect(find.text('Julho de 2026'), findsOneWidget);
    expect(find.text('Junho de 2026'), findsOneWidget);
  });

  testWidgets('filtrar por tópico esconde os outros tópicos', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(loadDelay);

    // Antes do filtro: itens de AppSec e de Regulatório aparecem os dois.
    expect(
      find.textContaining('adoção de segurança de aplicações'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Nova resolução da ANPD'),
      findsOneWidget,
    );

    final Finder appSecChip = find.widgetWithText(FilterChip, 'AppSec');
    await tester.ensureVisible(appSecChip);
    await tester.pump();
    await tester.tap(appSecChip);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('adoção de segurança de aplicações'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Nova resolução da ANPD'),
      findsNothing,
    );
  });

  testWidgets('o selo de benchmark aparece nos 3 itens marcados', (
    WidgetTester tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(loadDelay);

    expect(find.text('Benchmark de setor'), findsNWidgets(3));
  });
}
