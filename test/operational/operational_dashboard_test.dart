import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/dashboard/presentation/operational_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const OperationalDashboardScreen(),
      ),
    );
  }

  void setLogicalSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('mostra os 3 blocos de demonstração, ainda como "Em breve"', (
    WidgetTester tester,
  ) async {
    setLogicalSize(tester, const Size(390, 844));

    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text('Incidentes ativos'), findsOneWidget);
    expect(find.text('Vulnerabilidades priorizadas'), findsOneWidget);
    expect(find.text('Fila do turno'), findsOneWidget);
    expect(find.text('Em breve'), findsNWidgets(3));
  });

  testWidgets(
    'em large, os 3 blocos ficam lado a lado em vez de empilhados '
    '(HU-W-09)',
    (WidgetTester tester) async {
      setLogicalSize(tester, const Size(1400, 900));

      await tester.pumpWidget(harness());
      await tester.pump();

      // Os 3 continuam presentes...
      expect(find.text('Incidentes ativos'), findsOneWidget);
      expect(find.text('Vulnerabilidades priorizadas'), findsOneWidget);
      expect(find.text('Fila do turno'), findsOneWidget);

      // ...e lado a lado: mesmo topo (top-aligned numa Row), diferente do
      // empilhamento vertical do layout estreito.
      final double topIncidentes =
          tester.getTopLeft(find.text('Incidentes ativos')).dy;
      final double topVulnerabilidades =
          tester.getTopLeft(find.text('Vulnerabilidades priorizadas')).dy;
      expect(topIncidentes, topVulnerabilidades);
    },
  );
}
